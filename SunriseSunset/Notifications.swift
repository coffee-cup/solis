//
//  Notifications.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-13.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class Notifications {
    
    lazy var defaults = Defaults.defaults
    lazy var application = UIApplication.shared
    
    let sunriseTypes: [SunType] = [.sunrise]
    let sunsetTypes: [SunType] = [.sunset]
    let lastLightTypes: [SunType] = [.astronomicalDusk, .nauticalDusk, .civilDusk]
    let firstLightTypes: [SunType] = [.astronomicalDawn, .nauticalDawn, .civilDawn]
    
    lazy var notificationCountDefaults = UserDefaults.init(suiteName: "NotificationCount")!
    
    init() {
        // Default notification counts
        notificationCountDefaults.register(defaults: [
            SunType.astronomicalDawn.description : 0,
            SunType.nauticalDawn.description : 0,
            SunType.civilDawn.description : 0,
            SunType.sunrise.description : 0,
            SunType.sunset.description : 0,
            SunType.civilDusk.description : 0,
            SunType.nauticalDusk.description : 0,
            SunType.astronomicalDusk.description : 0
        ])
        checkIfNotificationsTriggered()
        
        Bus.subscribeEvent(.notificationChange, observer: self, selector: #selector(scheduleNotifications))
        Bus.subscribeEvent(.changeNotificationPlace, observer: self, selector: #selector(changeNotificationPlace))
        scheduleNotifications()
    }
    
    @objc func scheduleNotifications() -> Bool {
        guard let location = SunLocation.getNotificationLocation() else {
            return false
        }
        
        let suntimes = SunLogic.todayTomorrow(location)
        
        let timeBefore: TimeInterval = defaults.double(forKey: "NotificationPreTime")
        
        let sunriseNoti = defaults.bool(forKey: "Sunrise")
        let sunsetNoti = defaults.bool(forKey: "Sunset")
        let firstLightNoti = defaults.bool(forKey: "FirstLight")
        let lastLightNoti = defaults.bool(forKey: "LastLight")
        
        var notificationTimes: [Suntime] = []
        
        if sunriseNoti {
            if let sunriseTime = SunLogic.sunrise(suntimes) {
                notificationTimes.append(sunriseTime)
            }
        } else {
            removeNotificationForTypes(sunriseTypes)
        }
        
        if sunsetNoti {
            if let sunsetTime = SunLogic.sunset(suntimes) {
                notificationTimes.append(sunsetTime)
            }
        } else {
            removeNotificationForTypes(sunsetTypes)
        }
        
        if firstLightNoti {
            if let firstLightTime = SunLogic.firstLight(suntimes) {
                notificationTimes.append(firstLightTime)
            }
        } else {
            removeNotificationForTypes(firstLightTypes)
        }
        
        if lastLightNoti {
            if let lastLightTime = SunLogic.lastLight(suntimes) {
                notificationTimes.append(lastLightTime)
            }
        } else {
            removeNotificationForTypes(lastLightTypes)
        }
        
        var triggered = false
        for suntime in notificationTimes {
            triggered = scheduleNotificationIfNotAlready(suntime)
        }
        return triggered
    }
    
    @objc func changeNotificationPlace() {
        let allTypes = firstLightTypes + sunriseTypes + sunsetTypes + lastLightTypes
        removeNotificationForTypes(allTypes)
        scheduleNotifications()
    }
    
    func scheduleNotificationIfNotAlready(_ suntime: Suntime) -> Bool {
        if !notificationAlreadyScheduled(suntime) {
            let notification = createNotification(suntime)
            application.scheduleLocalNotification(notification)
            print("scheduled notification for \(suntime.type.description)")
            increaseCountForType(suntime.type.description)
            return true
        } else {
            print("\(suntime.type.description) notification already scheduled")
            return false
        }
    }
    
    func createNotification(_ suntime: Suntime) -> UILocalNotification {
        let notification = UILocalNotification()
        notification.fireDate = suntime.date
        notification.alertBody = suntime.type.message
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = [
            "date": suntime.date.description,
            "type": suntime.type.description
        ]
        
        return notification
    }
    
    func notificationAlreadyScheduled(_ suntime: Suntime) -> Bool {
        let notifications = application.scheduledLocalNotifications ?? []
        let matches = notifications.filter { notification in
            guard let userInfo = notification.userInfo else {
                return false
            }
            
            guard let type = userInfo["type"] as? String else {
                return false
            }
            
            return type == suntime.type.description
        }
        return matches.count > 0
    }
    
    func removeNotificationForTypes(_ types: [SunType]) {
        for type in types {
            let notifications = application.scheduledLocalNotifications ?? []
            for notification in notifications {
                guard let userInfo = notification.userInfo else {
                    continue
                }
                
                guard let notiType = userInfo["type"] as? String else {
                    continue
                }
                
                if notiType == type.description {
                    application.cancelLocalNotification(notification)
                    print("removed notification for \(notiType)")
                    decreaseCountForType(notiType)
                }
            }
        }
    }
    
    func checkIfNotificationsTriggered() {
        var allTypeCounts: [String : Int] = [
            SunType.astronomicalDawn.description : 0,
            SunType.nauticalDawn.description : 0,
            SunType.civilDawn.description : 0,
            SunType.sunrise.description : 0,
            SunType.sunset.description : 0,
            SunType.civilDusk.description : 0,
            SunType.nauticalDusk.description : 0,
            SunType.astronomicalDusk.description : 0
        ]
        
        let localNotifications = application.scheduledLocalNotifications ?? []
        
        // Loop through local notifications and tally for each type
        for notification in localNotifications {
            if let userInfo = notification.userInfo {
                if let type = userInfo["type"] as? String {
                    if let count = allTypeCounts[type] {
                        allTypeCounts[type] = count + 1
                    }
                }
            }
        }
        
        // Compare the count with the count in defaults
        // If allTypeCounts[type] < notificationCountDefaults[type] then
        // a notification for that type was triggered
        // After comparing each type, set notificationCountDefaults[type] to allTypeCounts[type]
        for (type, count) in allTypeCounts {
            let defaultCount = notificationCountDefaults.integer(forKey: type)
            let countDifference = defaultCount - count
            if countDifference > 0 {
                // countDifference notifications were triggered for type :)
                for _ in 1...countDifference {
                    // send analytics event as many times as notification was triggered
                    Analytics.notificationTriggeredForType(type)
                }
                notificationCountDefaults.set(count, forKey: type)
            }
        }
    }
    
    func increaseCountForType(_ type: String) {
        let notificationCount = getCountForType(type)
        notificationCountDefaults.set(notificationCount + 1, forKey: type)
    }
    
    func decreaseCountForType(_ type: String) {
        let notificationCount = getCountForType(type)
        let newNotificationCount = notificationCount - 1 < 0 ? 0 : notificationCount - 1
        notificationCountDefaults.set(newNotificationCount, forKey: type)
    }
    
    func getCountForType(_ type: String) -> Int {
        return notificationCountDefaults.integer(forKey: type)
    }
}
