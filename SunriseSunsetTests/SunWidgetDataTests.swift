import CoreLocation
import Foundation
import Testing

@testable import SunriseSunset

struct SunWidgetDataTests {
    private let zone = TimeZone(identifier: "America/Vancouver")!
    private let coordinate = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)

    private func date(_ month: Int = 9, _ day: Int = 25, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    @Test func eventBoundaryAdvancesAtSunset() {
        let now = date()
        let days = SunWidgetData.days(from: now, location: coordinate, timeZone: zone)
        let sunset = days[1].sunset!
        let before = SunWidgetData.snapshot(at: sunset.addingTimeInterval(-1), locationName: "Vancouver", timeZone: zone, days: days)
        let after = SunWidgetData.snapshot(at: sunset, locationName: "Vancouver", timeZone: zone, days: days)
        #expect(before.nextEvent?.name == "Sunset")
        #expect(before.nextRiseOrSet?.name == "Sunset")
        #expect(before.isDaylight)
        #expect(after.nextEvent?.name == "Last light")
        #expect(after.nextRiseOrSet?.name == "Sunrise")
        #expect(!after.isDaylight)
    }

    @Test func localMidnightChangesTheDayAndKeepsTomorrowAvailable() {
        let now = date(hour: 23)
        let days = SunWidgetData.days(from: now, location: coordinate, timeZone: zone)
        let midnight = days[2].interval.start
        let entry = SunWidgetData.snapshot(at: midnight, locationName: "Vancouver", timeZone: zone, days: days)
        #expect(entry.sunrise == days[2].sunrise)
        #expect(entry.nextRiseOrSet?.date == days[2].sunrise)
        let dates = SunWidgetData.timelineDates(from: now, days: days)
        #expect(dates.contains(midnight))
        #expect(dates.contains(days[2].sunrise!))
        #expect(dates == dates.sorted())
        #expect(Set(dates).count == dates.count)
        let final = SunWidgetData.snapshot(at: dates.last!, locationName: "Vancouver", timeZone: zone, days: days)
        #expect(final.nextRiseOrSet != nil)
    }

    @Test func polarDayDoesNotInventAnEventOrSunPosition() {
        let place = CLLocationCoordinate2D(latitude: 78.2232, longitude: 15.6267)
        let oslo = TimeZone(identifier: "Europe/Oslo")!
        let now = date(6, 15)
        let days = SunWidgetData.days(from: now, location: place, timeZone: oslo)
        let entry = SunWidgetData.snapshot(at: now, locationName: "Longyearbyen", timeZone: oslo, days: days)
        #expect(entry.sunrise == nil)
        #expect(entry.sunset == nil)
        #expect(entry.nextRiseOrSet == nil)
        #expect(entry.locationName == "Longyearbyen")
        #expect(entry.daylight == .allDay)
        #expect(entry.daylightDuration == TimeInterval(24 * 60 * 60))
        #expect(entry.daylightChange == 0)
        #expect(entry.isDaylight)
        #expect((0...24).allSatisfy { entry.sunlineHeight(at: Double($0) / 24) > 0 })
    }

    @Test func polarNightHasNoFalseSunriseAndStaysBelowHorizon() {
        let place = CLLocationCoordinate2D(latitude: 78.2232, longitude: 15.6267)
        let oslo = TimeZone(identifier: "Europe/Oslo")!
        let now = date(12, 15)
        let days = SunWidgetData.days(from: now, location: place, timeZone: oslo)
        let entry = SunWidgetData.snapshot(at: now, locationName: "Longyearbyen", timeZone: oslo, days: days)
        #expect(entry.sunrise == nil)
        #expect(entry.sunset == nil)
        #expect(entry.nextRiseOrSet == nil)
        #expect(entry.daylight == .allNight)
        #expect(entry.daylightDuration == 0)
        #expect(entry.daylightChange == 0)
        #expect(!entry.isDaylight)
        #expect((0...24).allSatisfy { entry.sunlineHeight(at: Double($0) / 24) < 0 })
    }

    @Test func curveCrossesHorizonAtRealEventsAndIncludesNight() {
        let now = date()
        let days = SunWidgetData.days(from: now, location: coordinate, timeZone: zone)
        let entry = SunWidgetData.snapshot(at: now, locationName: "Vancouver", timeZone: zone, days: days)
        let interval = entry.dayInterval!
        let rise = entry.sunrise!.timeIntervalSince(interval.start) / interval.duration
        let set = entry.sunset!.timeIntervalSince(interval.start) / interval.duration
        #expect(abs(entry.sunlineHeight(at: rise)) < 0.0001)
        #expect(abs(entry.sunlineHeight(at: set)) < 0.0001)
        #expect(entry.sunlineHeight(at: rise / 2) < 0)
        #expect(entry.sunlineHeight(at: (rise + set) / 2) > 0)
        #expect(entry.sunlineHeight(at: (set + 1) / 2) < 0)
    }

    @Test func daylightWidthVariesByLatitude() {
        let now = date(6, 15)
        func daylightFraction(_ coordinate: CLLocationCoordinate2D) -> Double {
            let day = SunWidgetDay(date: now, location: coordinate, timeZone: .gmt)!
            return day.sunset!.timeIntervalSince(day.sunrise!) / day.interval.duration
        }
        let equator = daylightFraction(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let north = daylightFraction(CLLocationCoordinate2D(latitude: 64, longitude: 0))
        #expect(equator > 0.49 && equator < 0.52)
        #expect(north > 0.8)
        #expect(north > equator)
    }

    @Test func daylightCanContinueAcrossLocalMidnight() {
        let reykjavik = TimeZone(identifier: "Atlantic/Reykjavik")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = reykjavik
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 21, hour: 0))!
        let days = SunWidgetData.days(from: now, location: CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426), timeZone: reykjavik)
        #expect(days[0].sunset! < now)
        #expect(days[1].sunset! > now)
        #expect(days[1].daylight == .normal)
        let entry = SunWidgetData.snapshot(at: now, locationName: "Reykjavík", timeZone: reykjavik, days: days)
        #expect(entry.isDaylight)
        #expect(entry.sunlineHeight(at: 0) > 0)
        #expect(entry.skyPhase == "Daylight")
    }

    @Test func daylightSavingUsesCalendarDays() {
        let newYork = TimeZone(identifier: "America/New_York")!
        let days = SunWidgetData.days(from: date(11, 1),
                                      location: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                                      timeZone: newYork)
        #expect(days[1].interval.duration == 25 * 60 * 60)
        #expect(days[1].interval.end == days[2].interval.start)
        #expect(days[2].interval.end == days[3].interval.start)
    }

    @Test func daylightComparisonUsesThePreviousLocalDay() {
        for (month, increasing) in [(2, true), (9, false)] {
            let now = date(month, 15)
            let days = SunWidgetData.days(from: now, location: coordinate, timeZone: zone)
            let entry = SunWidgetData.snapshot(at: now, locationName: "Vancouver", timeZone: zone, days: days)
            #expect((entry.daylightChange! > 0) == increasing)
            #expect(entry.daylightDuration == days[1].sunset!.timeIntervalSince(days[1].sunrise!))
            let tomorrow = SunWidgetData.snapshot(at: days[2].interval.start, locationName: "Vancouver", timeZone: zone, days: days)
            #expect(tomorrow.daylightChange == days[2].daylightDuration - days[1].daylightDuration)
            let withoutYesterday = SunWidgetData.snapshot(at: now, locationName: "Vancouver", timeZone: zone, days: Array(days.dropFirst()))
            #expect(withoutYesterday.daylightChange == nil)
        }
    }

    @Test func skyMovesDownWhileNowStaysCentred() {
        let days = SunWidgetData.days(from: date(), location: coordinate, timeZone: zone)
        let sunrise = days[1].sunrise!
        let before = SunWidgetData.snapshot(at: sunrise.addingTimeInterval(-3600), locationName: "Vancouver", timeZone: zone, days: days)
        let after = SunWidgetData.snapshot(at: sunrise.addingTimeInterval(3600), locationName: "Vancouver", timeZone: zone, days: days)
        #expect(before.skyPosition(for: before.date) == 0.5)
        #expect(after.skyPosition(for: after.date) == 0.5)
        #expect(before.skyPosition(for: sunrise) < 0.5)
        #expect(after.skyPosition(for: sunrise) > 0.5)
        #expect(before.skyPhase == "Twilight")
        #expect(after.skyPhase == "Daylight")
        for hour in 0..<24 {
            let entry = SunWidgetData.snapshot(at: date(hour: hour), locationName: "Vancouver", timeZone: zone, days: days)
            let positions = entry.skyStops.map(\.position)
            #expect(positions.first == 0)
            #expect(positions.last == 1)
            #expect(positions == positions.sorted())
        }
        let night = SunWidgetData.snapshot(at: date(hour: 23), locationName: "Vancouver", timeZone: zone, days: days)
        #expect(night.skyPhase == "Night")
    }

    @Test func polarSkyDoesNotInventADailySunset() {
        let place = CLLocationCoordinate2D(latitude: 90, longitude: 0)
        for (month, phase, type) in [(6, "Daylight", SunType.sunrise), (12, "Night", .middleNight)] {
            let now = date(month, 15)
            let days = SunWidgetData.days(from: now, location: place, timeZone: .gmt)
            let entry = SunWidgetData.snapshot(at: now, locationName: "North Pole", timeZone: .gmt, days: days)
            #expect(entry.skyPhase == phase)
            #expect(entry.skyStops.allSatisfy { $0.type == type })
        }
    }

    @Test func locationPersistsWithoutNetworkAndRetainsTimeZoneRules() {
        let place = SunWidgetPlace(name: "Vancouver", detail: "BC, Canada", latitude: 49.2827,
                                   longitude: -123.1207, timeZoneIdentifier: zone.identifier)
        let restored = SunWidgetPlace(identifier: place.identifier)
        #expect(restored == place)
        #expect(restored?.identifier == place.identifier)
        #expect(Set((0..<20).map { _ in place.identifier }).count == 1)
        #expect(restored?.timeZone.secondsFromGMT(for: date(1, 15)) == -8 * 60 * 60)
        #expect(restored?.timeZone.secondsFromGMT(for: date(7, 15)) == -7 * 60 * 60)
        #expect(SunWidgetPlace(identifier: "invalid") == nil)
    }

    @Test func locationSelectionDistinguishesMissingAndZeroCoordinates() {
        let suite = "SolisWidgetDataTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(SunWidgetPlace.saved(in: defaults) == nil)
        defaults.set(false, forKey: "CurrentLocation")
        defaults.set(0.0, forKey: "LocationLatitude")
        defaults.set(0.0, forKey: "LocationLongitude")
        defaults.set("Equator", forKey: "LocationName")
        defaults.set(49.2827, forKey: "CurrentLocationLatitude")
        defaults.set(-123.1207, forKey: "CurrentLocationLongitude")
        defaults.set("Vancouver", forKey: "CurrentLocationName")
        #expect(SunWidgetPlace.saved(in: defaults)?.name == "Equator")
        #expect(SunWidgetPlace.saved(in: defaults)?.latitude == 0)
        #expect(SunWidgetPlace.saved(in: defaults, currentLocation: true)?.name == "Vancouver")
    }
    @Test func aSingleSunriseDoesNotBecomePolarNight() throws {
        let start = Date(timeIntervalSince1970: 1_781_481_600)
        let day = try #require(SunWidgetDay(date: start,
            location: CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426),
            timeZone: TimeZone(identifier: "Atlantic/Reykjavik")!))
        #expect(day.sunrise != nil && day.sunset == nil)
        #expect(day.daylight == .normal)
        #expect(day.daylightDuration > 20*3600 && day.daylightDuration < day.interval.duration)
        #expect(day.daylightIntervals.last?.end == day.interval.end)
        #expect(day.events.filter { $0.isRiseOrSet }.count == 1)
    }

}
