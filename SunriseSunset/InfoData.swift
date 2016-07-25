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
        case .Day: return UIImage(named: "day_image")
        case .CivilTwilight: return UIImage(named: "civil_image")
        case .NauticalTwilight: return UIImage(named: "nautical_image")
        case .AstronomicalTwilight: return UIImage(named: "astronomical_image")
        case .Night: return UIImage(named: "night_image")
        }
    }
    
    var text: String {
        switch(self) {
        case .Day: return "Day is defined as the time between sunrise and sunset. During the day everything is visible."
        case .CivilTwilight: return "Civil twilight is defined as the period when the sun lies between 6 and 0 degrees below the horizon. Of the celestial bodies, only the brightest stars and planets remain visible during civil twilight. Illumination is bright enough to distinguish objects in the landscape."
        case .NauticalTwilight: return "Nautical twilight is defined as the period when the sun lies between 12 and 6 degrees below the horizon. At this time, stars remain visible in the sky for navigational purposes and objects on the horizon are only just visible."
        case .AstronomicalTwilight: return "Astronomical twilight is defined as the period when the sun lies between 18 and 12 degrees below the horizon. At this time, point light sources such as stars remain visible in the sky, but fainter objects such as nebulae and galaxies are not visible. The majority of observers would consider astronomical twilight to be effectively dark."
        case .Night: return "Night is defined as the time between Astronomical dusk and Astronomical dawn. During this time the sun is at least 18 degrees below the horizon. The only light illuminating the sky at this time is from the moon and stars."
        }
    }
    
    var photoDescription: String {
        switch(self) {
        case .Day: return "Vancouver BC during the day"
        case .CivilTwilight: return "Civil twilight looking over lake Ontario to Toronto"
        case .NauticalTwilight: return "Nautical twilight looking towards Garraf National Park"
        case .AstronomicalTwilight: return "Astronomical twilight at Paranal Observatory in Chile"
        case .Night: return "Milky way at night"
        }
    }
    
    var learnMoreURL: String {
        switch(self) {
        case .Day: return "https://en.wikipedia.org/wiki/Day"
        case .CivilTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html#civil"
        case .NauticalTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html#nautical"
        case .AstronomicalTwilight: return "https://www.timeanddate.com/astronomy/different-types-twilight.html#astronomical"
        case .Night: return "https://en.wikipedia.org/wiki/Night"
        }
    }
}
