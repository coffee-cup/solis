//
//  DateExtensionsTests.swift
//  SunriseSunsetTests
//

import Foundation
import Testing

@testable import SunriseSunset

struct DateExtensionsTests {

    let base = Date(timeIntervalSince1970: 1_000_000)

    @Test func addDays() {
        #expect(base.addDays(1) == base.addingTimeInterval(86_400))
        #expect(base.addDays(-2) == base.addingTimeInterval(-172_800))
    }

    @Test func addHours() {
        #expect(base.addHours(3) == base.addingTimeInterval(10_800))
        #expect(base.addHours(-1) == base.addingTimeInterval(-3600))
    }

    @Test func comparisons() {
        let later = base.addingTimeInterval(1)

        #expect(later.isGreaterThanDate(base))
        #expect(!base.isGreaterThanDate(later))
        #expect(base.isLessThanDate(later))
        #expect(!later.isLessThanDate(base))
        #expect(base.equalToDate(base))
        #expect(!base.equalToDate(later))
    }

    @Test func differenceInMinutesIsAbsoluteAndTruncating() {
        let other = base.addingTimeInterval(150) // 2.5 minutes

        #expect(base.getDifferenceInMinutes(other) == 2)
        #expect(other.getDifferenceInMinutes(base) == 2)
    }

    @Test func differenceInHoursFloors() {
        let other = base.addingTimeInterval(119 * 60)

        #expect(base.getDifferenceInHours(other) == 1)
        #expect(other.getDifferenceInHours(base) == 1)
    }
}
