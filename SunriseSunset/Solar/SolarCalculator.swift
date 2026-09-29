import Foundation

nonisolated enum SolarThreshold: Double, CaseIterable, Codable, Sendable {
    case astronomical = -18, nautical = -12, civil = -6, blue = -4
    case horizon = -0.8333333333333334, golden = 6
}

nonisolated struct SolarEvent: Equatable, Sendable {
    enum Direction: Int, Sendable { case rising = 1, setting = -1 }
    let date: Date
    let threshold: SolarThreshold
    let direction: Direction
}

nonisolated struct SolarDay: Sendable {
    enum State: Sendable { case above, below, crossing }
    let interval: DateInterval
    let events: [SolarEvent]
    let initialAltitude: Double
    let minimumAltitude: Double
    let maximumAltitude: Double

    func state(at threshold: SolarThreshold) -> State {
        if minimumAltitude > threshold.rawValue { return .above }
        if maximumAltitude < threshold.rawValue { return .below }
        return .crossing
    }

    /// Actual portions of this civil day above a threshold, including partial days.
    func intervals(above threshold: SolarThreshold) -> [DateInterval] {
        var start: Date? = initialAltitude >= threshold.rawValue ? interval.start : nil
        var result: [DateInterval] = []
        for event in events where event.threshold == threshold {
            if event.direction == .rising { start = event.date }
            else if let beginning = start {
                if event.date > beginning { result.append(DateInterval(start: beginning, end: event.date)) }
                start = nil
            }
        }
        if let start, start < interval.end { result.append(DateInterval(start: start, end: interval.end)) }
        return result
    }

    func intervals(between lower: SolarThreshold, and upper: SolarThreshold) -> [DateInterval] {
        let upperIntervals = intervals(above: upper)
        return intervals(above: lower).flatMap { segment -> [DateInterval] in
            var cursor = segment.start
            var result: [DateInterval] = []
            for excluded in upperIntervals where excluded.end > cursor && excluded.start < segment.end {
                if excluded.start > cursor { result.append(DateInterval(start: cursor, end: min(excluded.start, segment.end))) }
                cursor = max(cursor, excluded.end)
            }
            if cursor < segment.end { result.append(DateInterval(start: cursor, end: segment.end)) }
            return result
        }
    }
}

/// Pure, offline calculator. Dates and coordinates are the only inputs.
nonisolated enum SolarCalculator {
    enum CalculationError: Error { case invalidCoordinate, unsupportedDate, invalidInterval }
    static let rootPrecision: TimeInterval = 0.05

    static func day(containing date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) throws -> SolarDay {
        guard date.timeIntervalSince1970.isFinite else { throw CalculationError.unsupportedDate }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard (1801...2099).contains(calendar.component(.year, from: date)),
              let interval = calendar.dateInterval(of: .day, for: date) else { throw CalculationError.unsupportedDate }
        return try calculate(interval: interval, latitude: latitude, longitude: longitude)
    }

    static func calculate(interval: DateInterval, latitude: Double, longitude: Double) throws -> SolarDay {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw CalculationError.invalidCoordinate
        }
        let start = interval.start.timeIntervalSince1970, end = interval.end.timeIntervalSince1970
        guard start.isFinite, end.isFinite, end > start, end-start <= 172800 else { throw CalculationError.invalidInterval }
        // A one-day margin permits civil dates in zones on either side of UTC.
        guard start >= -5333212800, end <= 4102531200 else { throw CalculationError.unsupportedDate }
        var values: [Double: Double] = [:]
        func at(_ t: Double) -> Double {
            if let value = values[t] { return value }
            let value = SolarPosition.altitude(at: Date(timeIntervalSince1970: t), latitude: latitude, longitude: longitude)
            values[t] = value
            return value
        }
        // Extra samples outside the interval bracket extrema close to midnight.
        // Solar altitude has at most two turning points per rotation; explicitly
        // locating them catches short grazing crossings missed by a sign-only scan.
        let step = 1800.0
        let samples = Array(stride(from: start-step, through: end+step, by: step)) + [end+step]
        var points = [start, end]
        points += samples.filter { $0 > start && $0 < end }
        for i in 1..<(samples.count-1) {
            let a = at(samples[i-1]), b = at(samples[i]), c = at(samples[i+1])
            guard (b-a)*(c-b) < 0 else { continue }
            let sign = b > a ? 1.0 : -1.0
            var lo = samples[i-1], hi = samples[i+1]
            while hi-lo > rootPrecision {
                let x = lo+(hi-lo)/3, y = hi-(hi-lo)/3
                if sign*at(x) < sign*at(y) { lo = x } else { hi = y }
            }
            let extremum = (lo+hi)/2
            if extremum > start && extremum < end { points.append(extremum) }
        }
        points = Array(Set(points)).sorted()
        var events: [SolarEvent] = []
        for threshold in SolarThreshold.allCases {
            for (left,right) in zip(points, points.dropFirst()) {
                var lo = left, hi = right
                let positive = at(lo) >= threshold.rawValue
                guard positive != (at(hi) >= threshold.rawValue) else { continue }
                let direction: SolarEvent.Direction = positive ? .setting : .rising
                while hi-lo > rootPrecision {
                    let mid = (lo+hi)/2
                    if (at(mid) >= threshold.rawValue) == positive { lo = mid } else { hi = mid }
                }
                let root = (lo+hi)/2
                if root >= start && root < end {
                    events.append(SolarEvent(date: Date(timeIntervalSince1970: root), threshold: threshold, direction: direction))
                }
            }
        }
        let heights = points.map(at)
        return SolarDay(interval: interval, events: events.sorted { $0.date < $1.date }, initialAltitude: at(start),
                        minimumAltitude: heights.min()!, maximumAltitude: heights.max()!)
    }
}
