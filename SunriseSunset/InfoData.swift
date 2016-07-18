//
//  InfoData.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-17.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

enum InfoData {
    case Day
    case CivilTwilight
    case NauticalTwilight
    case AstronomicalTwilight
    case Night
    
    var title: String {
        switch(self) {
        case .Day: return "Day"
        case .CivilTwilight: return "Civil Twilight"
        case .NauticalTwilight: return "Nautical Twilight"
        case .AstronomicalTwilight: return "Astronomical Twilight"
        case .Night: return "Night"
        }
    }
    
    var image: UIImage? {
        switch(self) {
        case .Day: return UIImage(named: "civil_twilight")
        case .CivilTwilight: return UIImage(named: "civil_twilight")
        case .NauticalTwilight: return UIImage(named: "civil_twilight")
        case .AstronomicalTwilight: return UIImage(named: "civil_twilight")
        case .Night: return UIImage(named: "civil_twilight")
        }
    }
    
    var text: String {
        switch(self) {
        case .Day: return "Day desc"
        case .CivilTwilight: return "Civil Twilight desc"
        case .NauticalTwilight: return "Nautical Twilight desc"
        case .AstronomicalTwilight: return "Astronomical Twilight desc"
        case .Night: return "Night desc"
        }
    }
    
    var learnMoreURL: String {
        switch(self) {
        case .Day: return "https://www.timeanddate.com/astronomy/different-types-twilight.html"
        case .CivilTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html"
        case .NauticalTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html"
        case .AstronomicalTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html"
        case .Night: return "https://www.timeanddate.com/astronomy/different-types-twilight.html"
        }
    }
}
