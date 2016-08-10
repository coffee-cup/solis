//
//  Suntime.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-15.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

enum SunDay {
    case Yesterday
    case Today
    case Tomorrow
}

class Suntime: Comparable {
    
    var dateComponents: NSDateComponents!
    var date: NSDate!
    var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let type: SunType
    var colour: CGColorRef {
        return type.colour
    }
    var marker: Bool {
        return isLast ? true : type.marker
    }
    var day: SunDay!
    
    // Possibility for refactor, to only set marker if last time
    var isLast: Bool = true
    
    var neverHappens = false
    
    let formatter = NSDateFormatter()
    
    init(type: SunType, day: SunDay) {
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        self.type = type
        self.day = day
        formatter.dateFormat = "MMMM d HH:mm"
    }
    
    func setValues(day: NSDate, dateComponents: NSDateComponents) {
        self.dateComponents = dateComponents
        
        let dayComponents = calendar.components([.Day, .Month, .Year], fromDate: day)
        self.dateComponents.year = dayComponents.year
        self.dateComponents.month = dayComponents.month
        self.dateComponents.day = dayComponents.day
        
        self.date = calendar.dateFromComponents(self.dateComponents)
    }
    
    func description() -> String {
        let dateString = formatter.stringFromDate(date)
        return "\(type.description): \(dateString)"
    }
}

func < (lhs: Suntime, rhs: Suntime) -> Bool {
    return lhs.date.isLessThanDate(rhs.date)
}

func == (lhs: Suntime, rhs: Suntime) -> Bool {
    return Int(lhs.date.timeIntervalSinceDate(rhs.date)) == 0
}