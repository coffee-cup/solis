//
//  NotificationScheduler.swift
//  SunriseSunset
//

import Foundation
import UserNotifications

// Raw values double as the defaults toggle keys and the notification
// request identifiers, so re-adding a request replaces the pending one.
enum SunAlert: String, CaseIterable {
    case sunrise = "Sunrise"
    case sunset = "Sunset"
    case firstLight = "FirstLight"
    case lastLight = "LastLight"

    func nextTime(in suntimes: [Suntime]) -> Suntime? {
        switch self {
        case .sunrise: return SunLogic.sunrise(suntimes)
        case .sunset: return SunLogic.sunset(suntimes)
        case .firstLight: return SunLogic.firstLight(suntimes)
        case .lastLight: return SunLogic.lastLight(suntimes)
        }
    }
}

enum NotificationScheduler {

    static func requestAuthorization() async -> Bool {
        let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    // Schedules one pending request per enabled alert type for the next
    // future occurrence at the notification place (or current location).
    // Idempotent: same-identifier adds replace, disabled types are removed.
    static func reschedule() async {
        let center = UNUserNotificationCenter.current()

        guard let location = SunLocation.getNotificationLocation() else {
            return
        }
        let suntimes = SunLogic.todayTomorrow(location)

        for alert in SunAlert.allCases {
            guard Defaults.defaults.bool(forKey: alert.rawValue) else {
                center.removePendingNotificationRequests(withIdentifiers: [alert.rawValue])
                print("removed pending \(alert.rawValue) notification")
                continue
            }

            guard let suntime = alert.nextTime(in: suntimes) else { continue }

            let content = UNMutableNotificationContent()
            content.body = suntime.type.message
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: suntime.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: alert.rawValue, content: content, trigger: trigger)
            do {
                try await center.add(request)
                print("scheduled \(alert.rawValue) notification for \(suntime.date!)")
            } catch {
                print("failed to schedule \(alert.rawValue) notification: \(error)")
            }
        }
    }
}
