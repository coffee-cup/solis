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
    lazy var application = UIApplication.sharedApplication()
    
    let sunriseTypes: [SunType] = [.Sunrise]
    let sunsetTypes: [SunType] = [.Sunset]
    let lastLightTypes: [SunType] = [.AstronomicalDusk, .NauticalDusk, .CivilDusk]
    let firstLightTypes: [SunType] = [.AstronomicalDawn, .NauticalDawn, .CivilDawn]
    
    init() {
        Bus.subscribeEvent(.NotificationChange, observer: self, selector: #selector(scheduleNotifications))
        Bus.subscribeEvent(.ChangeNotificationPlace, observer: self, selector: #selector(changeNotificationPlace))
        scheduleNotifications()
    }
    
    @objc func scheduleNotifications() -> Bool {
        guard let location = Location.getNotificationLocation() else {
            return false
        }
        
        let suntimes = SunLogic.todayTomorrow(location)
        
        let timeBefore: NSTimeInterval = defaults.doubleForKey("NotificationPreTime")
        
        let sunriseNoti = defaults.boolForKey("Sunrise")
        let sunsetNoti = defaults.boolForKey("Sunset")
        let firstLightNoti = defaults.boolForKey("FirstLight")
        let lastLightNoti = defaults.boolForKey("LastLight")
        
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
    
    func scheduleNotificationIfNotAlready(suntime: Suntime) -> Bool {
        if !notificationAlreadyScheduled(suntime) {
            let notification = createNotification(suntime)
            application.scheduleLocalNotification(notification)
            print("scheduled notification for \(suntime.type.description)")
            return true
        } else {
            print("\(suntime.type.description) notification already scheduled")
            return false
        }
    }
    
    func createNotification(suntime: Suntime) -> UILocalNotification {
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
    
    func notificationAlreadyScheduled(suntime: Suntime) -> Bool {
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
    
    func removeNotificationForTypes(types: [SunType]) {
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
                }
            }
        }
    }
}