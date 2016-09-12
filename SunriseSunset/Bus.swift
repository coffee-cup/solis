//
//  Events.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

enum MessageType {
//    case MenuIn
//    case MenuOut
    case timeFormat
    case foregrounded
    case sendMenuIn
    case notificationChange
    case locationUpdate
    case locationChanged
    case showStatusBar
    case fetchTimeZone
    case gotTimeZone
    case changeNotificationPlace
    
    var description: String {
        switch self {
//        case .MenuIn: return "MenuIn";
//        case .MenuOut: return "MenuOut";
        case .timeFormat: return "TimeFormat";
        case .foregrounded: return NSNotification.Name.UIApplicationWillEnterForeground
        case .sendMenuIn: return "SendMenuIn"
        case .notificationChange: return "NotificationChange"
        case .locationUpdate: return "LocationUpdate"
        case .locationChanged: return "LocationChanged"
        case .showStatusBar: return "ShowStatusBar"
        case .fetchTimeZone: return "FetchTimeZone"
        case .gotTimeZone: return "GotTimeZone"
        case .changeNotificationPlace: return "ChangeNotificationPlace"
        }
    }
}

class Bus {
    
    static let ns = NotificationCenter.default()
    static let defaults = UserDefaults.standard()
    
    class func sendMessage(_ message: MessageType, data: [NSObject: AnyObject]?) {
        ns.post(name: Notification.Name(rawValue: message.description), object: nil, userInfo: data)
    }
    
    class func subscribeEvent(_ message: MessageType, observer: AnyObject, selector: Selector) {
        ns.addObserver(observer, selector: selector, name: message.description, object: nil)
        
    }
    
    class func subscribeDefaultChange(_ message: MessageType, observer: NSObject, selector: Selector) {
        defaults.addObserver(observer, forKeyPath: message.description, options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    class func removeSubscriptions(_ observer: AnyObject) {
        ns.removeObserver(observer)
    }
    
    class func removeDefaultSeubscriptions(_ observer: NSObject, message: MessageType) {
        defaults.removeObserver(observer, forKeyPath: message.description)
    }
    
}
