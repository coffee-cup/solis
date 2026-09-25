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
        let prefix = current ? "CurrentLocation" : "Location"
        guard let latitude = defaults.object(forKey: prefix + "Latitude") as? Double,
              let longitude = defaults.object(forKey: prefix + "Longitude") as? Double,
              CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            return nil
        }
        let zone = current ? TimeZone.current :
            (TimeZone(secondsFromGMT: defaults.integer(forKey: "LocationTimeZoneOffset")) ?? .current)
        return Self(name: defaults.string(forKey: prefix + "Name") ?? "Selected location",
                    detail: "", latitude: latitude, longitude: longitude, timeZoneIdentifier: zone.identifier)
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

    var daylightDuration: TimeInterval {
        switch daylight {
        case .allDay: 24 * 60 * 60
        case .allNight: 0
        case .normal: sunset!.timeIntervalSince(sunrise!)
        }
    }

    init(date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        interval = calendar.dateInterval(of: .day, for: date)!
        let times = SunLogic.calculateTimesForDate(
            date, location: location, timezone: timeZone, day: .today)
        let rise = times.first { $0.type == .sunrise }!.date!
        let set = times.first { $0.type == .sunset }!.date!
        let duration = set.timeIntervalSince(rise)
        daylight = duration >= 86_399 ? .allDay : (duration <= 1 ? .allNight : .normal)
        let overnightType: SunType = daylight == .allDay ? .sunrise :
            [(SunType.civilDawn, SunType.civilDusk), (.nauticalDawn, .nauticalDusk),
             (.astronomicalDawn, .astronomicalDusk)].first { start, end in
                let first = times.first { $0.type == start }!.date!
                let last = times.first { $0.type == end }!.date!
                return last.timeIntervalSince(first) >= 86_399
            }?.0 ?? .middleNight
        // The library uses a zero-length pair for continuous night and a
        // 24-hour pair for continuous day. Neither is an actual event.
        for (start, end) in [(SunType.sunrise, SunType.sunset), (.civilDawn, .civilDusk),
                             (.nauticalDawn, .nauticalDusk), (.astronomicalDawn, .astronomicalDusk)] {
            if let first = times.first(where: { $0.type == start }),
               let last = times.first(where: { $0.type == end }) {
                let span = abs(last.date.timeIntervalSince(first.date))
                if span <= 1 || span >= 86_399 {
                    first.neverHappens = true
                    last.neverHappens = true
                }
            }
        }
        sunrise = SunLogic.getSunType(times, type: .sunrise)?.date
        sunset = SunLogic.getSunType(times, type: .sunset)?.date
        skyEvents = [WidgetSkyEvent(date: interval.start, type: overnightType)]
            + times.filter { !$0.neverHappens }.map { WidgetSkyEvent(date: $0.date, type: $0.type) }

        let firstLight = SunLogic.getFirstSunType(
            times, sunTypes: [.astronomicalDawn, .nauticalDawn, .civilDawn])
        let lastLight = SunLogic.getFirstSunType(
            times, sunTypes: [.astronomicalDusk, .nauticalDusk, .civilDusk])
        events = [
            firstLight.map { WidgetSunEvent(name: "First light", date: $0.date, symbol: "sun.horizon", isRiseOrSet: false) },
            sunrise.map { WidgetSunEvent(name: "Sunrise", date: $0, symbol: "sunrise", isRiseOrSet: true) },
            sunset.map { WidgetSunEvent(name: "Sunset", date: $0, symbol: "sunset", isRiseOrSet: true) },
            lastLight.map { WidgetSunEvent(name: "Last light", date: $0.date, symbol: "moon.stars", isRiseOrSet: false) }
        ].compactMap { $0 }.sorted { $0.date < $1.date }
    }
}

/// A date-driven snapshot shared by the widget provider and its tests.
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
    let skyEvents: [WidgetSkyEvent]

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

    var isDaylight: Bool {
        if daylight == .allDay { return true }
        guard let sunrise, let sunset else { return false }
        return date >= sunrise && date < sunset
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
        guard let dayInterval, let sunrise, let sunset else { return -1 }
        let rise = sunrise.timeIntervalSince(dayInterval.start) / dayInterval.duration
        let set = sunset.timeIntervalSince(dayInterval.start) / dayInterval.duration
        if fraction < rise {
            return -cos(fraction / max(rise, 0.001) * .pi / 2)
        }
        if fraction > set {
            return -sin((fraction - set) / max(1 - set, 0.001) * .pi / 2)
        }
        return sin((fraction - rise) / max(set - rise, 0.001) * .pi)
    }

    static func snapshot(at date: Date, locationName: String, timeZone: TimeZone, days: [SunWidgetDay]) -> Self {
        let today = days.first { date >= $0.interval.start && date < $0.interval.end }
        let yesterday = days.first { $0.interval.end == today?.interval.start }
        let future = days.flatMap(\.events).filter { $0.date > date }.sorted { $0.date < $1.date }
        return Self(date: date, locationName: locationName, timeZone: timeZone,
                    nextEvent: future.first, nextRiseOrSet: future.first { $0.isRiseOrSet },
                    sunrise: today?.sunrise, sunset: today?.sunset,
                    dayInterval: today?.interval, daylight: today?.daylight,
                    daylightDuration: today?.daylightDuration,
                    daylightChange: today.flatMap { day in yesterday.map { day.daylightDuration - $0.daylightDuration } },
                    skyEvents: days.flatMap(\.skyEvents).sorted { $0.date < $1.date })
    }

    static func unknown(at date: Date) -> Self {
        Self(date: date, locationName: nil, timeZone: .current,
             nextEvent: nil, nextRiseOrSet: nil, sunrise: nil, sunset: nil, dayInterval: nil, daylight: nil,
             daylightDuration: nil, daylightChange: nil, skyEvents: [])
    }

    static func days(from date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone) -> [SunWidgetDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)
        // Adjacent days supply gradient stops and keep a next event in the final entry.
        return (-1..<3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map {
                SunWidgetDay(date: $0, location: location, timeZone: timeZone)
            }
        }
    }

    static func timelineDates(from now: Date, days: [SunWidgetDay]) -> [Date] {
        let end = now.addingTimeInterval(24 * 60 * 60)
        var dates = stride(from: 0.0, through: 24 * 60 * 60, by: 15 * 60).map {
            now.addingTimeInterval($0)
        }
        // Exact event and local-midnight entries prevent stale labels between arc updates.
        dates += days.flatMap { [$0.interval.start] + $0.events.map(\.date) }
            .filter { $0 > now && $0 <= end }
        return Array(Set(dates)).sorted()
    }
}
