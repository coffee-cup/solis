//
//  BackgroundRefresh.swift
//  SunriseSunset
//

import BackgroundTasks
import Foundation

// Periodic app refresh that re-schedules sun notifications, replacing the
// pre-iOS 13 background fetch API. Inert on the simulator.
enum BackgroundRefresh {
    static let taskIdentifier = "xyz.jakerunzer.solis.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            schedule()
            let work = Task {
                await NotificationScheduler.reschedule()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
        print("background refresh task registered")
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("background refresh task submitted")
        } catch {
            // BGTaskScheduler is unavailable on the simulator.
            print("background refresh submit failed: \(error)")
        }
    }
}
