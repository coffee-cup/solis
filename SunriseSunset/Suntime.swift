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
    case yesterday
    case today
    case tomorrow
}

class Suntime: Comparable {
    
    var dateComponents: DateComponents!
    var date: Date!
    var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let type: SunType
    var colour: CGColor {
        return type.colour
    }
    var marker: Bool {
        return isLast ? true : type.marker
    }
    var day: SunDay!
    
    // Possibility for refactor, to only set marker if last time
    var isLast: Bool = true
    
    var neverHappens = false
    
    let formatter = DateFormatter()
    
    init(type: SunType, day: SunDay) {
        calendar.timeZone = TimeZone.ReferenceType.local
        
        self.type = type
        self.day = day
        formatter.dateFormat = "MMMM d HH:mm"
    }
    
    func setValues(_ day: Date, dateComponents: DateComponents) {
        self.dateComponents = dateComponents
        
        let dayComponents = calendar.dateComponents([.day, .month, .year], from: day)
        self.dateComponents.year = dayComponents.year
        self.dateComponents.month = dayComponents.month
        self.dateComponents.day = dayComponents.day
        
        self.date = calendar.date(from: self.dateComponents)
    }
    
    func description() -> String {
        let dateString = formatter.string(from: date)
        return "\(type.description): \(dateString)"
    }
}

func < (lhs: Suntime, rhs: Suntime) -> Bool {
    return lhs.date.isLessThanDate(rhs.date)
}

func == (lhs: Suntime, rhs: Suntime) -> Bool {
    return Int(lhs.date.timeIntervalSince(rhs.date)) == 0
}
