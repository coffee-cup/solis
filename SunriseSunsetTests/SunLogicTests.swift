//
//  SunLogicTests.swift
//  SunriseSunsetTests
//

import CoreLocation
import Foundation
import Testing

@testable import SunriseSunset

private let vancouver = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)
private let vancouverTZ = TimeZone(identifier: "America/Vancouver")!

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, timeZone: TimeZone) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

private func suntime(_ type: SunType, day: SunDay = .today, date: Date, neverHappens: Bool = false) -> Suntime {
    let time = Suntime(type: type, day: day)
    time.date = date
    time.neverHappens = neverHappens
    return time
}

struct SunLogicTests {

    @Test func vancouverWinterTimesMatchReference() {
        let noon = date(2026, 1, 15, timeZone: vancouverTZ)
        let times = SunLogic.calculateTimesForDate(noon, location: vancouver, timezone: vancouverTZ, day: .today)

        #expect(times.count == 8)
        #expect(times.allSatisfy { !$0.neverHappens })

        // Reference: NOAA solar calculator for 2026-01-15 (PST)
        let expectedSunrise = date(2026, 1, 15, 8, 1, timeZone: vancouverTZ)
        let expectedSunset = date(2026, 1, 15, 16, 43, timeZone: vancouverTZ)
        let tolerance: TimeInterval = 300

        let sunrise = times.first { $0.type == .sunrise }!
        let sunset = times.first { $0.type == .sunset }!
        #expect(abs(sunrise.date.timeIntervalSince(expectedSunrise)) < tolerance)
        #expect(abs(sunset.date.timeIntervalSince(expectedSunset)) < tolerance)
    }

    @Test func vancouverWinterEventsAreOrdered() {
        let noon = date(2026, 1, 15, timeZone: vancouverTZ)
        let times = SunLogic.calculateTimesForDate(noon, location: vancouver, timezone: vancouverTZ, day: .today)

        let ordered = times.sorted().map(\.type)
        #expect(ordered == [.astronomicalDawn, .nauticalDawn, .civilDawn, .sunrise, .sunset, .civilDusk, .nauticalDusk, .astronomicalDusk])
    }

    @Test func midnightSunNeverRisesOrSets() {
        let longyearbyen = CLLocationCoordinate2D(latitude: 78.2232, longitude: 15.6267)
        let osloTZ = TimeZone(identifier: "Europe/Oslo")!
        let noon = date(2026, 6, 15, timeZone: osloTZ)
        let times = SunLogic.calculateTimesForDate(noon, location: longyearbyen, timezone: osloTZ, day: .today)

        #expect(times.first { $0.type == .sunrise }!.neverHappens)
        #expect(times.first { $0.type == .sunset }!.neverHappens)
    }

    @Test func highLatitudeSummerSkipsAstronomicalTwilight() {
        // At 49°N near the solstice the sun never reaches 18° below the horizon.
        let noon = date(2026, 6, 21, timeZone: vancouverTZ)
        let times = SunLogic.calculateTimesForDate(noon, location: vancouver, timezone: vancouverTZ, day: .today)

        #expect(times.first { $0.type == .astronomicalDawn }!.neverHappens)
        #expect(times.first { $0.type == .astronomicalDusk }!.neverHappens)
        #expect(!times.first { $0.type == .sunrise }!.neverHappens)
        #expect(!times.first { $0.type == .sunset }!.neverHappens)
    }

    @Test func neverHappensRequiresExact24HourSpan() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        #expect(SunLogic.neverHappens(start, date2: start.addDays(1)))
        #expect(SunLogic.neverHappens(start.addDays(1), date2: start))
        #expect(!SunLogic.neverHappens(start, date2: start.addingTimeInterval(86399)))
        #expect(!SunLogic.neverHappens(start, date2: start.addingTimeInterval(86401)))
    }

    @Test func getSunTypeReturnsEarliestMatch() {
        let early = suntime(.sunrise, date: Date(timeIntervalSince1970: 1000))
        let late = suntime(.sunrise, day: .tomorrow, date: Date(timeIntervalSince1970: 2000))
        let other = suntime(.sunset, date: Date(timeIntervalSince1970: 500))

        #expect(SunLogic.getSunType([late, other, early], type: .sunrise) === early)
    }

    @Test func getSunTypeFiltersNeverHappensAndDay() {
        let never = suntime(.sunrise, date: Date(timeIntervalSince1970: 1000), neverHappens: true)
        let tomorrow = suntime(.sunrise, day: .tomorrow, date: Date(timeIntervalSince1970: 2000))

        #expect(SunLogic.getSunType([never], type: .sunrise) == nil)
        #expect(SunLogic.getSunType([never, tomorrow], type: .sunrise, day: .today) == nil)
        #expect(SunLogic.getSunType([never, tomorrow], type: .sunrise, day: .tomorrow) === tomorrow)
    }

    @Test func getFirstSunTypeRespectsTypePriorityOverDate() {
        let dawn = suntime(.civilDawn, date: Date(timeIntervalSince1970: 5000))
        let sunrise = suntime(.sunrise, date: Date(timeIntervalSince1970: 1000))

        #expect(SunLogic.getFirstSunType([dawn, sunrise], sunTypes: [.civilDawn, .sunrise]) === dawn)
    }

    @Test func futureTimesDropsPastTimes() {
        let past = suntime(.sunset, date: Date().addingTimeInterval(-3600))
        let future = suntime(.sunrise, date: Date().addingTimeInterval(3600))

        let result = SunLogic.futureTimes([past, future])
        #expect(result.count == 1)
        #expect(result.first === future)
    }

    @Test func suntimesCompareByDate() {
        let earlier = suntime(.sunrise, date: Date(timeIntervalSince1970: 1000))
        let later = suntime(.sunset, date: Date(timeIntervalSince1970: 2000))

        #expect(earlier < later)
        #expect(!(later < earlier))
    }
}
