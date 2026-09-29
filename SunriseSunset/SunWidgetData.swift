import CoreLocation
import Foundation

/// Fixed widget locations carry their time zone so they remain usable offline.
struct SunWidgetPlace: Codable, Hashable, Sendable {
    let name: String
    let detail: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }

    var identifier: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(self).base64EncodedString()) ?? ""
    }

    init(name: String, detail: String, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        self.name = name
        self.detail = detail
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    init?(identifier: String) {
        guard let data = Data(base64Encoded: identifier),
              let place = try? JSONDecoder().decode(Self.self, from: data),
              CLLocationCoordinate2DIsValid(place.coordinate),
              TimeZone(identifier: place.timeZoneIdentifier) != nil else { return nil }
        self = place
    }

    static func saved(in defaults: UserDefaults, currentLocation: Bool? = nil) -> Self? {
        let current = currentLocation ?? (defaults.object(forKey: "CurrentLocation") as? Bool ?? true)
        guard let place = StoredPlace.saved(in: defaults, current: current) else { return nil }
        let zone = current ? TimeZone.current : place.timeZone
        return Self(name: place.name, detail: place.detail, latitude: place.latitude, longitude: place.longitude, timeZoneIdentifier: zone.identifier)
    }
}

struct WidgetSunEvent {
    let name: String
    let date: Date
    let symbol: String
    let isRiseOrSet: Bool
}

enum WidgetDaylight {
    case normal, allDay, allNight
}

struct WidgetSkyEvent {
    let date: Date
    let type: SunType
}

struct WidgetSkyStop {
    let position: Double
    let type: SunType
}

struct SunWidgetDay {
    let interval: DateInterval
    let events: [WidgetSunEvent]
    let sunrise: Date?
    let sunset: Date?
    let daylight: WidgetDaylight
    let skyEvents: [WidgetSkyEvent]

    let daylightIntervals: [DateInterval]
    let goldenHourIntervals: [DateInterval]
    let localNoon: Date

    var daylightDuration: TimeInterval { daylightIntervals.reduce(0) { $0 + $1.duration } }

    init?(date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard date.timeIntervalSince1970.isFinite,
              let dayInterval = calendar.dateInterval(of: .day, for: date),
              let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return nil }
        interval = dayInterval
        localNoon = noon
        guard let solar = SunLogic.solarDay(date, location: location, timezone: timeZone) else { return nil }
        daylightIntervals = solar.intervals(above: .horizon)
        goldenHourIntervals = solar.intervals(between: .blue, and: .golden)
        switch solar.state(at: .horizon) {
        case .above: daylight = .allDay
        case .below: daylight = .allNight
        case .crossing: daylight = .normal
        }
        let times = SunLogic.times(for: solar, day: .today)
        sunrise = SunLogic.getSunType(times, type: .sunrise)?.date
        sunset = SunLogic.getSunType(times, type: .sunset)?.date
        skyEvents = [WidgetSkyEvent(date: interval.start, type: SunLogic.skyType(altitude: solar.initialAltitude))]
            + times.map { WidgetSkyEvent(date: $0.date, type: $0.type) }
            + [WidgetSkyEvent(date: interval.end, type: SunLogic.skyType(altitude: SolarPosition.altitude(at: interval.end, latitude: location.latitude, longitude: location.longitude)))]
        let selected = SunLogic.lightEvents(times, morning: true) + SunLogic.lightEvents(times, morning: false)
            + times.filter { $0.type == .sunrise || $0.type == .sunset }
        events = selected.map { time in
            WidgetSunEvent(name: time.type == .sunrise ? "Sunrise" : time.type == .sunset ? "Sunset" : time.type.morning ? "First light" : "Last light",
                           date: time.date, symbol: time.type == .sunrise ? "sunrise" : time.type == .sunset ? "sunset" : time.type.morning ? "sun.horizon" : "moon.stars",
                           isRiseOrSet: time.type == .sunrise || time.type == .sunset)
        }.sorted { $0.date < $1.date }
    }

}

struct SunWidgetData {
    let date: Date
    let locationName: String?
    let timeZone: TimeZone
    let nextEvent: WidgetSunEvent?
    let nextRiseOrSet: WidgetSunEvent?
    let sunrise: Date?
    let sunset: Date?
    let dayInterval: DateInterval?
    let daylight: WidgetDaylight?
    let daylightDuration: TimeInterval?
    let daylightChange: TimeInterval?
    let daylightIntervals: [DateInterval]
    let skyEvents: [WidgetSkyEvent]
    let isGoldenHour: Bool

    // Match the app's six-hour viewport: future above, past below, now at 0.5.
    func skyPosition(for eventDate: Date) -> Double {
        0.5 - eventDate.timeIntervalSince(date) / (6 * 60 * 60)
    }

    var skyStops: [WidgetSkyStop] {
        let events = skyEvents.sorted { $0.date > $1.date }
        let above = events.last { skyPosition(for: $0.date) < 0 }
        let below = events.first { skyPosition(for: $0.date) > 1 }
        var stops = events.filter { (0...1).contains(skyPosition(for: $0.date)) }
            .map { WidgetSkyStop(position: skyPosition(for: $0.date), type: $0.type) }
        if let above { stops.insert(WidgetSkyStop(position: 0, type: above.type), at: 0) }
        if let below { stops.append(WidgetSkyStop(position: 1, type: below.type)) }
        return stops
    }

    var skyPhase: String {
        switch skyEvents.last(where: { $0.date <= date })?.type {
        case .sunrise: "Daylight"
        case .astronomicalDusk, .middleNight, .none: "Night"
        default: "Twilight"
        }
    }

    var lightPhase: String {
        if isGoldenHour { return "Golden hour" }
        if daylight == .allDay { return "Midnight sun" }
        if daylight == .allNight { return "Polar night" }
        if isDaylight {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            return calendar.component(.hour, from: date) < 12 ? "Morning" : "Afternoon"
        }
        return skyPhase
    }

    var isDaylight: Bool {
        daylightIntervals.contains { date >= $0.start && date < $0.end }
    }

    var dayProgress: Double {
        guard let dayInterval else { return 0 }
        return min(1, max(0, date.timeIntervalSince(dayInterval.start) / dayInterval.duration))
    }

    /// Schematic height above the horizon across the local calendar day.
    /// The zero crossings match real events; this is not an elevation angle.
    func sunlineHeight(at fraction: Double) -> Double {
        if daylight == .allDay { return 0.65 - 0.25 * cos(fraction * 2 * .pi) }
        if daylight == .allNight { return -0.65 - 0.25 * cos(fraction * 2 * .pi) }
        guard let dayInterval else { return -1 }
        let sample = dayInterval.start.addingTimeInterval(fraction * dayInterval.duration)
        if let daylight = daylightIntervals.first(where: { sample >= $0.start && sample <= $0.end }) {
            return sin(sample.timeIntervalSince(daylight.start) / daylight.duration * .pi)
        }
        let previousSet = daylightIntervals.map(\.end).filter { $0 < sample }.max()
            ?? dayInterval.start.addingTimeInterval(-dayInterval.duration)
        let nextRise = daylightIntervals.map(\.start).filter { $0 > sample }.min()
            ?? dayInterval.end.addingTimeInterval(dayInterval.duration)
        return -sin(sample.timeIntervalSince(previousSet) / nextRise.timeIntervalSince(previousSet) * .pi)
    }

    static func snapshot(at date: Date, locationName: String, timeZone: TimeZone, days: [SunWidgetDay]) -> Self {
        guard !days.isEmpty else { return .unknown(at: date) }
        let today = days.first { date >= $0.interval.start && date < $0.interval.end }
        let yesterday = days.first { $0.interval.end == today?.interval.start }
        let future = days.flatMap(\.events).filter { $0.date > date }.sorted { $0.date < $1.date }
        return Self(date: date, locationName: locationName, timeZone: timeZone,
                    nextEvent: future.first, nextRiseOrSet: future.first { $0.isRiseOrSet },
                    sunrise: today?.sunrise, sunset: today?.sunset,
                    dayInterval: today?.interval, daylight: today?.daylight,
                    daylightDuration: today?.daylightDuration,
                    daylightChange: today.flatMap { day in yesterday.map { day.daylightDuration - $0.daylightDuration } },
                    daylightIntervals: mergedIntervals(days.flatMap(\.daylightIntervals)),
                    skyEvents: days.flatMap(\.skyEvents).sorted { $0.date < $1.date },
                    isGoldenHour: today?.goldenHourIntervals.contains { date >= $0.start && date < $0.end } ?? false)
    }

    static func mergedIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        var result: [DateInterval] = []
        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let previous = result.last, previous.end >= interval.start {
                result[result.count-1] = DateInterval(start: previous.start, end: max(previous.end, interval.end))
            } else { result.append(interval) }
        }
        return result
    }

    static func unknown(at date: Date) -> Self {
        Self(date: date, locationName: nil, timeZone: .current,
             nextEvent: nil, nextRiseOrSet: nil, sunrise: nil, sunset: nil, dayInterval: nil, daylight: nil,
             daylightDuration: nil, daylightChange: nil, daylightIntervals: [], skyEvents: [], isGoldenHour: false)
    }

    static func days(from date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone) -> [SunWidgetDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard date.timeIntervalSince1970.isFinite else { return [] }
        let start = calendar.startOfDay(for: date)
        // Adjacent days supply gradient stops and keep a next event in the final entry.
        return (-1..<3).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return SunWidgetDay(date: date, location: location, timeZone: timeZone)
        }
    }

    static func timelineDates(from now: Date, days: [SunWidgetDay]) -> [Date] {
        let end = now.addingTimeInterval(24 * 60 * 60)
        var dates = stride(from: 0.0, through: 24 * 60 * 60, by: 15 * 60).map {
            now.addingTimeInterval($0)
        }
        // Phase boundaries prevent stale labels and markers between regular updates.
        dates += days.flatMap { day in
            [day.interval.start, day.localNoon] + day.events.map(\.date)
                + day.goldenHourIntervals.flatMap { [$0.start, $0.end] }
        }
            .filter { $0 > now && $0 <= end }
        return Array(Set(dates)).sorted()
    }
}
