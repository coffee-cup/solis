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
        
        let timeBefore: NSTimeInterval = defaults.doubleForKey("NotificationPreTime")
        
        let sunriseNoti = defaults.boolForKey("Sunrise")
        let sunsetNoti = defaults.boolForKey("Sunset")
        let firstLightNoti = defaults.boolForKey("FirstLight")
        let lastLightNoti = defaults.boolForKey("LastLight")
        
        print("\n")
        if sunriseNoti {
            print("sunrise")
        }
        if sunsetNoti {
            print("sunset")
        }
        if firstLightNoti {
            print("first light")
        }
        if lastLightNoti {
            print("last light")
        }
    }
}