//
//  Notifications.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-13.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation

class Notifications {
    
    lazy var defaults = NSUserDefaults.standardUserDefaults()
    
    init() {
        Bus.subscribeEvent(.NotificationChange, observer: self, selector: #selector(scheduleNotifications))
    }
    
    @objc func scheduleNotifications() {
        guard let location = Location.getLocation() else {
            return
        }
        let today = NSDate()
        let tomorrow = today.addDays(1)
        let suntimes = SunLogic.calculateTimesForDate(today, location: location)
            + SunLogic.calculateTimesForDate(tomorrow, location: location)
        
        let timeBefore: NSTimeInterval = defaults.doubleForKey("NotificationPreTime")
        
        let sunriseNoti = defaults.boolForKey("Sunrise")
        let sunsetNoti = defaults.boolForKey("Sunset")
        let firstLightNoti = defaults.boolForKey("FirstLight")
        let lastLightNoti = defaults.boolForKey("LastLight")
        
        print("\n")
        var notificationTimes: [Suntime] = []
        if sunriseNoti {
            print("sunrise")
            if let sunriseTime = SunLogic.getSunrise(suntimes) {
                notificationTimes.append(sunriseTime)
                print(sunriseTime.description())
            }
        }
        if sunsetNoti {
            print("sunset")
            if let sunsetTime = SunLogic.getSunset(suntimes) {
                notificationTimes.append(sunsetTime)
                print(sunsetTime.description())
            }
        }
        if firstLightNoti {
            print("first light")
            if let firstLightTime = SunLogic.getFirstLight(suntimes) {
                notificationTimes.append(firstLightTime)
                print(firstLightTime.description())
            }
        }
        if lastLightNoti {
            print("last light")
            if let lastLightTime = SunLogic.getLastLight(suntimes) {
                notificationTimes.append(lastLightTime)
                print(lastLightTime.description())
            }
        }
    }
}