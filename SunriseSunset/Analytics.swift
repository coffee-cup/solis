//
//  Analytics.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-24.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import Crashlytics

class Analytics {
    class func openLocationChange() {
        Answers.logCustomEvent(withName: "Open Location Change", customAttributes: nil)
    }
    
    class func openInfoMenu() {
        Answers.logCustomEvent(withName: "Open Info Menu", customAttributes: nil)
    }
    
    class func openInfoPage(_ page: String) {
        Answers.logCustomEvent(withName: "Open Info Page", customAttributes: ["page": page])
    }
    
    class func openLearnMore(_ page: String) {
        Answers.logCustomEvent(withName: "Open Learn More", customAttributes: ["page": page])
    }
    
    class func selectLocation(_ current: Bool, sunPlace: SunPlace?) {
        if let sunPlace = sunPlace {
            Answers.logCustomEvent(withName: "Select Location", customAttributes: ["primary": sunPlace.primary, "secondary": sunPlace.secondary, "current": current])
        } else {
            Answers.logCustomEvent(withName: "Select Location", customAttributes: ["current": current])
        }
    }
    
    class func setNotificationPlace(_ current: Bool, sunPlace: SunPlace?) {
        if let sunPlace = sunPlace {
            Answers.logCustomEvent(withName: "Set Notification Place", customAttributes: ["primary": sunPlace.primary, "secondary": sunPlace.secondary, "current": current])
        } else {
            Answers.logCustomEvent(withName: "Set Notification Place", customAttributes: ["current": current])
        }
    }
    
    class func toggleNotificationForEvent(_ on: Bool, type: String) {
        Answers.logCustomEvent(withName: "Toggle Notification", customAttributes: ["on": on, "event": type])
    }
    
    class func notificationTriggeredForType(_ type: String) {
        Answers.logCustomEvent(withName: "Notification Triggered", customAttributes: ["type": type])
    }
}
