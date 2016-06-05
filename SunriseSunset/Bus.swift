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
    case MenuIn
    case TimeFormat
    
    var description: String {
        switch self {
        case .MenuIn: return "MenuIn";
        case .TimeFormat: return "TimeFormat";
        }
    }
}

class Bus {
    
    static let ns = NSNotificationCenter.defaultCenter()
    static let defaults = NSUserDefaults.standardUserDefaults()
    
    class func SendMessage(message: MessageType, data: [NSObject: AnyObject]?) {
        ns.postNotificationName(message.description, object: nil, userInfo: data)
    }
    
    class func subscribeEvent(message: MessageType, observer: AnyObject, selector: Selector) {
        ns.addObserver(observer, selector: selector, name: message.description, object: nil)
    }
    
    class func subscribeDefaultChange(message: MessageType, observer: NSObject, selector: Selector) {
        defaults.addObserver(observer, forKeyPath: message.description, options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    class func removeSubscriptions(observer: AnyObject) {
        ns.removeObserver(observer)
    }
    
    class func removeDefaultSeubscriptions(observer: NSObject, message: MessageType) {
        defaults.removeObserver(observer, forKeyPath: message.description)
    }
    
}