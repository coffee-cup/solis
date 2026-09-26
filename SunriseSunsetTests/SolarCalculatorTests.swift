import Foundation
import CryptoKit
import Testing
@testable import SunriseSunset

private final class SolarFixtureBundle {}
private struct SolarFixture: Decodable {
    let id: String, latitude: Double, longitude: Double, start: Double, end: Double
    struct Event: Decodable { let altitude: Double, direction: Int, timestamp: Double }
    struct State: Decodable { let altitude: Double, above: Bool, below: Bool }
    let events: [Event], states: [State]
}

struct SolarCalculatorTests {
    private func data(_ name: String) throws -> Data {
        let url = try #require(Bundle(for: SolarFixtureBundle.self).url(forResource: name, withExtension: "json", subdirectory: "Solar"))
        return try Data(contentsOf: url)
    }

    @Test func frozenReferenceFilesHaveNotChanged() throws {
        let manifest = try JSONDecoder().decode([String: String].self, from: data("manifest"))
        for (name, expected) in manifest {
            let actual = SHA256.hash(data: try data(String(name.dropLast(5)))).map { String(format: "%02x", $0) }.joined()
            #expect(actual == expected, "Changed independent fixture: \(name)")
        }
    }

    @Test func independentReferenceRegressions() throws {
        let original = try JSONDecoder().decode([SolarFixture].self, from: data("astronomy"))
        let adjudicated = try JSONDecoder().decode([SolarFixture].self, from: data("adjudicated"))
        let overrides = Dictionary(uniqueKeysWithValues: adjudicated.map { ($0.id, $0) })
        var failures: [String] = []
        var eventCount = 0
        // The host CLI checks every interval in CI. App-hosted tests cover all
        // adjudicated edge cases plus a distributed sample without blocking launch.
        let selected = original.enumerated().filter { $0.offset % 37 == 0 || overrides[$0.element.id] != nil }.map(\.element)
        for fixture in selected {
            let row = overrides[fixture.id] ?? fixture
            let interval = DateInterval(start: Date(timeIntervalSince1970: row.start), end: Date(timeIntervalSince1970: row.end))
            let result = try SolarCalculator.calculate(interval: interval, latitude: row.latitude, longitude: row.longitude)
            if result.events.count != row.events.count {
                failures.append("\(row.id): expected \(row.events.count) crossings, got \(result.events.count)")
                continue
            }
            for (actual, expected) in zip(result.events, row.events) {
                eventCount += 1
                if actual.threshold.rawValue != expected.altitude || actual.direction.rawValue != expected.direction ||
                    abs(actual.date.timeIntervalSince1970-expected.timestamp) > 60 || actual.date < interval.start || actual.date >= interval.end {
                    failures.append("\(row.id): \(expected.altitude) / \(expected.direction), error \(actual.date.timeIntervalSince1970-expected.timestamp)s")
                }
            }
            for expected in row.states {
                let state = result.state(at: try #require(SolarThreshold(rawValue: expected.altitude)))
                if (state == .above) != expected.above || (state == .below) != expected.below {
                    failures.append("\(row.id): incorrect continuous state at \(expected.altitude)")
                }
            }
        }
        #expect(original.count == 14_760)
        #expect(eventCount > 4_000)
        #expect(failures.isEmpty, "\(failures.count) reference failures: \(failures.prefix(30))")
    }

    @Test func invalidInputsAreRejected() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        for (lat,lon) in [(Double.nan,0.0),(0,.infinity),(91,0),(0,181)] {
            #expect(throws: SolarCalculator.CalculationError.self) {
                try SolarCalculator.day(containing: date, latitude: lat, longitude: lon, timeZone: .gmt)
            }
        }
        for year in [1800,2100] {
            let outside = Calendar(identifier: .gregorian).date(from: DateComponents(year:year,month:6,day:1))!
            #expect(throws: SolarCalculator.CalculationError.self) {
                try SolarCalculator.day(containing: outside, latitude:0,longitude:0,timeZone:.gmt)
            }
        }
    }

    @Test func crossingsHaveCorrectDirectionAndSmallAltitudeResidual() throws {
        // Deterministic global coverage independent of the fixture locations.
        var seed: UInt64 = 0x50115
        func random() -> Double { seed = seed &* 6364136223846793005 &+ 1; return Double(seed >> 11)/Double(UInt64(1)<<53) }
        for _ in 0..<300 {
            let lat = random()*180-90, lon = random()*360-180
            let date = Date(timeIntervalSince1970: 1_767_225_600 + random()*365*86400)
            let day = try SolarCalculator.day(containing:date,latitude:lat,longitude:lon,timeZone:.gmt)
            #expect(day.events.map(\.date) == day.events.map(\.date).sorted())
            for event in day.events {
                let before = SolarPosition.altitude(at:event.date.addingTimeInterval(-1),latitude:lat,longitude:lon)
                let after = SolarPosition.altitude(at:event.date.addingTimeInterval(1),latitude:lat,longitude:lon)
                let at = SolarPosition.altitude(at:event.date,latitude:lat,longitude:lon)
                #expect(abs(at-event.threshold.rawValue)<0.0002)
                #expect((after>before) == (event.direction == .rising))
            }
            for threshold in SolarThreshold.allCases {
                let intervals = day.intervals(above: threshold)
                #expect(intervals.allSatisfy { $0.start >= day.interval.start && $0.end <= day.interval.end && $0.duration > 0 })
                #expect(intervals.reduce(0) { $0+$1.duration } <= day.interval.duration)
            }
        }
    }

    @Test func calendarDaysCoverDSTAndDateLine() throws {
        for (zoneName,month,day,hours) in [("America/New_York",3,8,23.0),("America/New_York",11,1,25.0),("Australia/Lord_Howe",10,4,23.5),("Pacific/Kiritimati",9,25,24.0)] {
            let zone = TimeZone(identifier:zoneName)!
            var calendar = Calendar(identifier:.gregorian);calendar.timeZone=zone
            let date = calendar.date(from:DateComponents(year:2026,month:month,day:day,hour:12))!
            let result = try SolarCalculator.day(containing:date,latitude:0,longitude:0,timeZone:zone)
            #expect(result.interval.duration == hours*3600)
            #expect(result.events.allSatisfy { calendar.isDate($0.date,inSameDayAs:date) })
        }
    }

    @Test func photographicWindowsUseTrueCrossings() throws {
        var calendar = Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(identifier:"America/Vancouver")!
        let date = calendar.date(from:DateComponents(year:2026,month:1,day:15,hour:12))!
        let result = try SolarCalculator.day(containing:date,latitude:49.2827,longitude:-123.1207,timeZone:calendar.timeZone)
        let morning = try #require(result.intervals(between:.blue,and:.golden).first)
        let components = calendar.dateComponents([.hour,.minute],from:morning.end)
        #expect(components.hour == 8 && (53...55).contains(components.minute!))
        #expect(abs(SolarPosition.altitude(at:morning.end,latitude:49.2827,longitude:-123.1207)-6)<0.0002)
    }
}
