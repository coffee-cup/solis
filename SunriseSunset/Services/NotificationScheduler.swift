import Foundation
import UserNotifications

enum SunAlert: String, CaseIterable {
    case sunrise = "Sunrise", sunset = "Sunset", firstLight = "FirstLight", lastLight = "LastLight"

    func nextTime(in times: [Suntime], now: Date = Date()) -> Suntime? {
        switch self {
        case .sunrise: SunLogic.sunrise(times, now: now)
        case .sunset: SunLogic.sunset(times, now: now)
        case .firstLight: SunLogic.firstLight(times, now: now)
        case .lastLight: SunLogic.lastLight(times, now: now)
        }
    }
}

enum NotificationScheduler {
    private static var running = false
    private static var revision = 0

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func trigger(for date: Date) -> UNCalendarNotificationTrigger {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        // Round forward so an alert cannot precede the calculated crossing.
        let instant = Date(timeIntervalSince1970: ceil(date.timeIntervalSince1970))
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: instant)
        components.calendar = calendar
        components.timeZone = .gmt
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    /// Serialises overlapping location/settings refreshes. A change during an
    /// awaited add reruns the entire plan, so an old request cannot win the race.
    static func reschedule() async {
        revision += 1
        guard !running else { return }
        running = true
        defer { running = false }
        let center = UNUserNotificationCenter.current()
        repeat {
            let currentRevision = revision
            let now = Date()
            let times = SunLocation.getNotificationLocation().map {
                SunLogic.todayTomorrow($0, now: now, timezone: SunLocation.notificationTimeZone)
            } ?? []
            for alert in SunAlert.allCases {
                guard Defaults.defaults.bool(forKey: alert.rawValue),
                      let time = alert.nextTime(in: times, now: now), time.date > Date() else {
                    center.removePendingNotificationRequests(withIdentifiers: [alert.rawValue])
                    continue
                }
                let content = UNMutableNotificationContent()
                content.body = time.type.message
                content.sound = .default
                let request = UNNotificationRequest(identifier: alert.rawValue, content: content, trigger: trigger(for: time.date))
                do { try await center.add(request) }
                catch { center.removePendingNotificationRequests(withIdentifiers: [alert.rawValue]) }
                if revision != currentRevision { break }
            }
            if revision == currentRevision { break }
        } while true
    }
}
