//
//  Suntime.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-15.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

enum SunType {
    case AstronomicalDawn
    case NauticalDawn
    case CivilDawn
    case Sunrise
    case Sunset
    case CivilDusk
    case NauticalDusk
    case AstronomicalDusk
    
    var description: String {
        switch self {
        case .AstronomicalDawn: return "Astronomical Dawn";
        case .NauticalDawn: return "Nautical Dawn";
        case .CivilDawn: return "Civil Dawn";
        case .Sunrise: return "Sunrise";
        case .Sunset: return "Sunset";
        case .CivilDusk: return "Civil Dusk";
        case .NauticalDusk: return "Nautical Dusk";
        case .AstronomicalDusk: return "Astronomical Dusk";
        }
    }
    
    var marker: Bool {
        switch self {
        case .AstronomicalDawn: return true;
        case .NauticalDawn: return false;
        case .CivilDawn: return false;
        case .Sunrise: return true;
        case .Sunset: return true;
        case .CivilDusk: return false;
        case .NauticalDusk: return false;
        case .AstronomicalDusk: return true;
        }
    }
    
    var colour: CGColorRef {
        switch self {
        case .AstronomicalDawn: return astronomicalColour.CGColor as CGColorRef
        case .NauticalDawn: return nauticalColour.CGColor as CGColorRef
        case .CivilDawn: return civilColour.CGColor as CGColorRef
        case .Sunrise: return risesetColour.CGColor as CGColorRef
        case .CivilDusk: return civilColour.CGColor as CGColorRef
        case .NauticalDusk: return nauticalColour.CGColor as CGColorRef
        case .Sunset: return risesetColour.CGColor as CGColorRef
        case .AstronomicalDusk: return astronomicalColour.CGColor as CGColorRef
        }
    }
    
    var lineColour: UIColor {
        switch self {
        case .AstronomicalDawn: return lightLineColour;
        case .NauticalDawn: return lightLineColour;
        case .CivilDawn: return lightLineColour;
        case .Sunrise: return lightLineColour;
        case .Sunset: return darkLineColour;
        case .CivilDusk: return darkLineColour;
        case .NauticalDusk: return darkLineColour;
        case .AstronomicalDusk: return darkLineColour;
        }
    }
    
    var message: String {
        var message = ""
        if self == .AstronomicalDawn || self == .NauticalDawn || self == .CivilDawn {
            message = "The sun is awake now ☀️ Have a good day."
        } else if self == .Sunrise {
            message = "The sun has risen! 🌄"
        } else if self == .Sunset {
            message = "The sun has set! 🌇"
        } else if self == .CivilDusk || self == .NauticalDusk || self == .AstronomicalDusk {
            message = "The sun has gone to sleep for the night 🌚 Goodnight."
        }
        return message
    }
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
    
    // Possibility for refactor, to only set marker if last time
    var isLast: Bool = true
    
    var neverHappens = false
    
    let formatter = NSDateFormatter()
    
    init(type: SunType) {
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        self.type = type
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