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
    
    var description: String {
        switch self {
        case .MenuIn: return "MenuIn";
        }
    }
}

class Bus {
    
    static let ns = NSNotificationCenter.defaultCenter()
    
    class func SendMessage(message: MessageType, data: [NSObject: AnyObject]?) {
        ns.postNotificationName(message.description, object: nil, userInfo: data)
    }
    
    class func subscribeEvent(message: MessageType, observer: AnyObject, selector: Selector) {
        ns.addObserver(observer, selector: selector, name: message.description, object: nil)
    }
    
    class func removeSubscriptions(observer: AnyObject) {
        ns.removeObserver(observer)
    }
    
}