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
        Answers.logCustomEventWithName("Open Location Change", customAttributes: nil)
    }
    
    class func openInfoMenu() {
        Answers.logCustomEventWithName("Open Info Menu", customAttributes: nil)
    }
    
    class func openInfoPage(page: String) {
        Answers.logCustomEventWithName("Open Info Page", customAttributes: ["page": page])
    }
    
    class func openLearnMore(page: String) {
        Answers.logCustomEventWithName("Open Learn More", customAttributes: ["page": page])
    }
    
    class func selectLocation(current: Bool, sunPlace: SunPlace?) {
        if let sunPlace = sunPlace {
            Answers.logCustomEventWithName("Select Location", customAttributes: ["primary": sunPlace.primary, "secondary": sunPlace.secondary, "current": current])
        } else {
            Answers.logCustomEventWithName("Select Location", customAttributes: ["current": current])
        }
    }
    
    class func setNotificationPlace(current: Bool, sunPlace: SunPlace?) {
        if let sunPlace = sunPlace {
            Answers.logCustomEventWithName("Set Notification Place", customAttributes: ["primary": sunPlace.primary, "secondary": sunPlace.secondary, "current": current])
        } else {
            Answers.logCustomEventWithName("Set Notification Place", customAttributes: ["current": current])
        }
    }
    
    class func toggleNotificationForEvent(on: Bool, type: String) {
        Answers.logCustomEventWithName("Toggle Notification", customAttributes: ["on": on, "event": type])
    }
    
    class func notificationTriggeredForType(type: String) {
        Answers.logCustomEventWithName("Notification Triggered", customAttributes: ["type": type])
    }
}