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
    case AstronomicalDusk
    case NauticalDusk
    case CivilDusk
    case Sunrise
    case Sunset
    case CivilTwilight
    case NauticalTwilight
    case AstronmicalTwilight
    
    var description: String {
        switch self {
        case .AstronomicalDusk: return "Astronomical Dusk";
        case .NauticalDusk: return "Nautical Dusk";
        case .CivilDusk: return "Civil Dusk";
        case .Sunrise: return "Sunrise";
        case .Sunset: return "Sunset";
        case .CivilTwilight: return "Civil Twilight";
        case .NauticalTwilight: return "Nautical Twilight";
        case .AstronmicalTwilight: return "Astronomical Twilight";
        }
    }
    
    var marker: Bool {
        switch self {
        case .AstronomicalDusk: return true;
        case .NauticalDusk: return false;
        case .CivilDusk: return false;
        case .Sunrise: return true;
        case .Sunset: return true;
        case .CivilTwilight: return false;
        case .NauticalTwilight: return false;
        case .AstronmicalTwilight: return true;
        }
    }
    
    var colour: CGColorRef {
        switch self {
        case .AstronomicalDusk: return darkColour.CGColor as CGColorRef
        case .Sunrise: return lightColour.CGColor as CGColorRef
        case .Sunset: return lightColour.CGColor as CGColorRef
        case .AstronmicalTwilight: return darkColour.CGColor as CGColorRef
        default: return UIColor.greenColor().CGColor as CGColorRef
        }
    }
    
    var lineColour: UIColor {
        switch self {
        case .AstronomicalDusk: return lightLineColour;
        case .NauticalDusk: return lightLineColour;
        case .CivilDusk: return lightLineColour;
        case .Sunrise: return lightLineColour;
        case .Sunset: return darkLineColour;
        case .CivilTwilight: return darkLineColour;
        case .NauticalTwilight: return darkLineColour;
        case .AstronmicalTwilight: return darkLineColour;
        }
    }
}

class Suntime {
    
    var dateComponents: NSDateComponents!
    var date: NSDate!
    var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let type: SunType
    var colour: CGColorRef {
        return type.colour
    }
    var marker: Bool {
        return type.marker
    }
    
    var sunline: Sunline
    
    let formatter = NSDateFormatter()
    
    init(type: SunType, view: UIView) {
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        self.type = type
        formatter.dateFormat = "MMMM d HH:mm"
        
        sunline = Sunline()
        sunline.createLine(view, type: type)
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