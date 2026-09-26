import Foundation
import Synchronization

/// Shared bounded cache. Gestures and widget entries reuse immutable daily results.
nonisolated final class SolarDayCache: Sendable {
    static let shared = SolarDayCache()
    private struct Key: Hashable {
        let start: Date, end: Date
        let latitude: Double, longitude: Double
    }
    private struct Storage {
        var values: [Key: SolarDay] = [:]
        var order: [Key] = []
    }
    private let storage = Mutex(Storage())
    private let capacity = 32

    func day(containing date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> SolarDay? {
        guard date.timeIntervalSince1970.isFinite, latitude.isFinite, longitude.isFinite else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return nil }
        let key = Key(start: interval.start, end: interval.end, latitude: latitude, longitude: longitude)
        if let cached = storage.withLock({ $0.values[key] }) { return cached }
        guard let result = try? SolarCalculator.day(containing: date, latitude: latitude, longitude: longitude, timeZone: timeZone) else { return nil }
        storage.withLock {
            if $0.values[key] == nil {
                if $0.order.count == capacity { $0.values.removeValue(forKey: $0.order.removeFirst()) }
                $0.order.append(key)
                $0.values[key] = result
            }
        }
        return result
    }
}
