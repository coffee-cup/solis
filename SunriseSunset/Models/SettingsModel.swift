//
//  SettingsModel.swift
//  SunriseSunset
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsModel {

    // Raw format string ("h:mm a", "HH:mm", "delta") — the same encoding the
    // widget and seeded plists read from the TimeFormat key.
    private(set) var timeFormat: String
    private(set) var alerts: [SunAlert: Bool]

    init() {
        timeFormat = Defaults.defaults.string(forKey: DefaultKey.timeFormat.description) ?? TimeFormat.hour12.description
        var states: [SunAlert: Bool] = [:]
        for alert in SunAlert.allCases {
            states[alert] = Defaults.defaults.bool(forKey: alert.rawValue)
        }
        alerts = states
    }

    func setTimeFormat(_ format: TimeFormat) {
        Defaults.defaults.set(format.description, forKey: DefaultKey.timeFormat.description)
        timeFormat = format.description
    }

    func isEnabled(_ alert: SunAlert) -> Bool {
        alerts[alert] ?? false
    }

    // Enabling prompts for notification permission first; a denial leaves the
    // toggle off, matching the old menu behaviour.
    func toggleAlert(_ alert: SunAlert) async {
        let enable = !isEnabled(alert)
        if enable {
            guard await NotificationScheduler.requestAuthorization() else { return }
        }
        Defaults.defaults.set(enable, forKey: alert.rawValue)
        alerts[alert] = enable
        await NotificationScheduler.reschedule()
    }
}
