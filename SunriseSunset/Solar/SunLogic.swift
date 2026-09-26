import Foundation
import CoreLocation

/// Presentation adapter. Only real crossings become Suntime values.
class SunLogic {
    static func solarDay(_ date: Date, location: CLLocationCoordinate2D, timezone: TimeZone) -> SolarDay? {
        SolarDayCache.shared.day(containing: date, latitude: location.latitude, longitude: location.longitude, timeZone: timezone)
    }

    static func type(for event: SolarEvent) -> SunType? {
        switch (event.threshold, event.direction) {
        case (.astronomical, .rising): .astronomicalDawn
        case (.nautical, .rising): .nauticalDawn
        case (.civil, .rising): .civilDawn
        case (.horizon, .rising): .sunrise
        case (.horizon, .setting): .sunset
        case (.civil, .setting): .civilDusk
        case (.nautical, .setting): .nauticalDusk
        case (.astronomical, .setting): .astronomicalDusk
        default: nil
        }
    }

    static func skyType(altitude: Double) -> SunType {
        if altitude >= SolarThreshold.horizon.rawValue { return .sunrise }
        if altitude >= -6 { return .civilDawn }
        if altitude >= -12 { return .nauticalDawn }
        if altitude >= -18 { return .astronomicalDawn }
        return .middleNight
    }

    static func times(for result: SolarDay, day: SunDay) -> [Suntime] {
        result.events.compactMap { event in
            guard let type = type(for: event) else { return nil }
            return Suntime(type: type, day: day, date: event.date)
        }
    }

    static func calculateTimesForDate(_ date: Date, location: CLLocationCoordinate2D, timezone: TimeZone = .current, day: SunDay) -> [Suntime] {
        guard let result = solarDay(date, location: location, timezone: timezone) else { return [] }
        return times(for: result, day: day)
    }

    static func window(from now: Date, location: CLLocationCoordinate2D, timezone: TimeZone) -> [(SunDay, SolarDay)] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let start = calendar.startOfDay(for: now)
        return zip(-1...2, SunDay.allCases).compactMap { offset, day in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start),
                  let solar = solarDay(date, location: location, timezone: timezone) else { return nil }
            return (day, solar)
        }
    }

    static func todayTomorrow(_ location: CLLocationCoordinate2D, now: Date = Date(), timezone: TimeZone = .current) -> [Suntime] {
        window(from: now, location: location, timezone: timezone).flatMap { times(for: $0.1, day: $0.0) }
    }

    static func futureTimes(_ times: [Suntime], now: Date = Date()) -> [Suntime] {
        times.filter { $0.date > now }.sorted()
    }

    static func getSunType(_ times: [Suntime], type: SunType, day: SunDay? = nil) -> Suntime? {
        times.filter { $0.type == type && (day == nil || $0.day == day) }.min()
    }

    static func getFirstSunType(_ times: [Suntime], sunTypes: [SunType], day: SunDay? = nil) -> Suntime? {
        sunTypes.lazy.compactMap { getSunType(times, type: $0, day: day) }.first
    }

    static func getNextSunType(_ times: [Suntime], type: SunType, now: Date = Date()) -> Suntime? {
        getSunType(futureTimes(times, now: now), type: type)
    }

    static func sunrise(_ times: [Suntime], now: Date = Date()) -> Suntime? { getNextSunType(times, type: .sunrise, now: now) }
    static func sunset(_ times: [Suntime], now: Date = Date()) -> Suntime? { getNextSunType(times, type: .sunset, now: now) }

    // Choose the deepest available threshold within each civil day BEFORE
    // filtering future events. A past dawn cannot turn today's civil dawn into first light.
    static func lightEvents(_ times: [Suntime], morning: Bool) -> [Suntime] {
        let types: [SunType] = morning ? [.astronomicalDawn, .nauticalDawn, .civilDawn] : [.astronomicalDusk, .nauticalDusk, .civilDusk]
        return SunDay.allCases.flatMap { day -> [Suntime] in
            let daily = times.filter { $0.day == day }
            guard let type = types.first(where: { type in daily.contains { $0.type == type } }) else { return [] }
            return daily.filter { $0.type == type }
        }.sorted()
    }

    static func firstLight(_ times: [Suntime], now: Date = Date()) -> Suntime? { futureTimes(lightEvents(times, morning: true), now: now).first }
    static func lastLight(_ times: [Suntime], now: Date = Date()) -> Suntime? { futureTimes(lightEvents(times, morning: false), now: now).first }
    static func nextEvent(_ times: [Suntime], now: Date = Date()) -> Suntime? {
        [firstLight(times, now: now), sunrise(times, now: now), sunset(times, now: now), lastLight(times, now: now)].compactMap { $0 }.min()
    }
}
