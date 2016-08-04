//
//  SunType.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-17.
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
            message = "The sun is awake now ☀️ Have a good day"
        } else if self == .Sunrise {
            message = "The sun has risen 🌄"
        } else if self == .Sunset {
            message = "The sun has set 🌇"
        } else if self == .CivilDusk || self == .NauticalDusk || self == .AstronomicalDusk {
            message = "The sun has gone to sleep for the night 🌚 Goodnight"
        }
        return message
    }
    
    var event: String {
        var message = ""
        if self == .AstronomicalDawn || self == .NauticalDawn || self == .CivilDawn {
            message = "First Light"
        } else if self == .Sunrise {
            message = "Sunrise"
        } else if self == .Sunset {
            message = "Sunset"
        } else if self == .CivilDusk || self == .NauticalDusk || self == .AstronomicalDusk {
            message = "Last Light"
        }
        return message
    }
}
