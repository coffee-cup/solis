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
    case astronomicalDawn
    case nauticalDawn
    case civilDawn
    case sunrise
    case sunset
    case civilDusk
    case nauticalDusk
    case astronomicalDusk
    case middleNight
    
    var description: String {
        switch self {
        case .astronomicalDawn: return "Astronomical Dawn";
        case .nauticalDawn: return "Nautical Dawn";
        case .civilDawn: return "Civil Dawn";
        case .sunrise: return "Sunrise";
        case .sunset: return "Sunset";
        case .civilDusk: return "Civil Dusk";
        case .nauticalDusk: return "Nautical Dusk";
        case .astronomicalDusk: return "Astronomical Dusk";
        case .middleNight: return "Middle of Night";
        }
    }
    
    var marker: Bool {
        switch self {
        case .astronomicalDawn: return true;
        case .nauticalDawn: return false;
        case .civilDawn: return false;
        case .sunrise: return true;
        case .sunset: return true;
        case .civilDusk: return false;
        case .nauticalDusk: return false;
        case .astronomicalDusk: return true;
        case .middleNight: return false;
        }
    }
    
    var colour: CGColor {
        switch self {
        case .astronomicalDawn: return astronomicalColour.cgColor as CGColor
        case .nauticalDawn: return nauticalColour.cgColor as CGColor
        case .civilDawn: return civilColour.cgColor as CGColor
        case .sunrise: return risesetColour.cgColor as CGColor
        case .civilDusk: return civilColour.cgColor as CGColor
        case .nauticalDusk: return nauticalColour.cgColor as CGColor
        case .sunset: return risesetColour.cgColor as CGColor
        case .astronomicalDusk: return astronomicalColour.cgColor as CGColor
        case .middleNight: return astronomicalColour.cgColor as CGColor
        }
    }
    
    var lineColour: UIColor {
        switch self {
        case .astronomicalDawn: return lightLineColour;
        case .nauticalDawn: return lightLineColour;
        case .civilDawn: return lightLineColour;
        case .sunrise: return lightLineColour;
        case .sunset: return darkLineColour;
        case .civilDusk: return darkLineColour;
        case .nauticalDusk: return darkLineColour;
        case .astronomicalDusk: return darkLineColour;
        case .middleNight: return middleLineColour;
        }
    }
    
    var message: String {
        var message = ""
        if self == .astronomicalDawn || self == .nauticalDawn || self == .civilDawn {
            message = "The sun is awake now ☀️ Have a good day"
        } else if self == .sunrise {
            message = "The sun has risen 🌄"
        } else if self == .sunset {
            message = "The sun has set 🌇"
        } else if self == .civilDusk || self == .nauticalDusk || self == .astronomicalDusk {
            message = "The sun has gone to sleep for the night 🌚 Goodnight"
        }
        return message
    }
    
    var event: String {
        var message = ""
        if self == .astronomicalDawn || self == .nauticalDawn || self == .civilDawn {
            message = "First Light"
        } else if self == .sunrise {
            message = "Sunrise"
        } else if self == .sunset {
            message = "Sunset"
        } else if self == .civilDusk || self == .nauticalDusk || self == .astronomicalDusk {
            message = "Last Light"
        }
        return message
    }
    
    var twilightDawn: Bool {
        switch self {
        case .astronomicalDawn: return true;
        case .nauticalDawn: return true;
        case .civilDawn: return true;
        case .sunrise: return false;
        case .sunset: return false;
        case .civilDusk: return false;
        case .nauticalDusk: return false;
        case .astronomicalDusk: return false;
        case .middleNight: return false;
        }
    }
    
    var twilightDusk: Bool {
        switch self {
        case .astronomicalDawn: return false;
        case .nauticalDawn: return false;
        case .civilDawn: return false;
        case .sunrise: return false;
        case .sunset: return false;
        case .civilDusk: return true;
        case .nauticalDusk: return true;
        case .astronomicalDusk: return true;
        case .middleNight: return false;
        }
    }
    
    var morning: Bool {
        switch self {
        case .astronomicalDawn: return true;
        case .nauticalDawn: return true;
        case .civilDawn: return true;
        case .sunrise: return true;
        case .sunset: return false;
        case .civilDusk: return false;
        case .nauticalDusk: return false;
        case .astronomicalDusk: return false;
        case .middleNight: return false;
        }
    }
    
    var night: Bool {
        switch self {
        case .astronomicalDawn: return false;
        case .nauticalDawn: return false;
        case .civilDawn: return false;
        case .sunrise: return false;
        case .sunset: return true;
        case .civilDusk: return true;
        case .nauticalDusk: return true;
        case .astronomicalDusk: return true;
        case .middleNight: return false;
        }
    }
    
    var degrees: Float {
        switch self {
        case .astronomicalDawn: return 18;
        case .nauticalDawn: return 12;
        case .civilDawn: return 6;
        case .sunrise: return 0;
        case .sunset: return 0;
        case .civilDusk: return 6;
        case .nauticalDusk: return 12;
        case .astronomicalDusk: return 18;
        case .middleNight: return 270;
        }
    }
}
