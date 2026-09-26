import Foundation

// Relative labels for the shared four-day presentation window.
enum SunDay: CaseIterable { case yesterday, today, tomorrow, dayAfterTomorrow }

/// A real event. Continuous daylight/twilight/night live in SolarDay states.
final class Suntime: Comparable {
    let date: Date
    let type: SunType
    let day: SunDay

    init(type: SunType, day: SunDay, date: Date) {
        self.type = type
        self.day = day
        self.date = date
    }

    static func < (lhs: Suntime, rhs: Suntime) -> Bool { lhs.date < rhs.date }
    static func == (lhs: Suntime, rhs: Suntime) -> Bool { lhs.date == rhs.date && lhs.type == rhs.type }
}
