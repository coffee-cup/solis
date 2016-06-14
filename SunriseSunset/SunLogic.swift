//
//  SunLogic.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-13.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import EDSunriseSet
import CoreLocation

class SunLogic {
    
    static let suntypes: [SunType] = [.AstronomicalDusk, .NauticalDusk, .CivilDusk, .Sunrise, .Sunset, .CivilDawn, .NauticalDawn, .AstronomicalDawn]
    
    // If there is no physical astronomical/nautical/civil twilight start or end (sun is never 18/16/12 degress below horizon)
    // Then the difference between start and end is a full 24 hours (86400 seconds)
    class func neverHappens(date1: NSDate, date2: NSDate) -> Bool {
        return abs(date1.timeIntervalSinceDate(date2)) == 86400
    }
    
    class func calculateTimesForDate(date: NSDate, location: CLLocationCoordinate2D, timezone: NSTimeZone = NSTimeZone.localTimeZone()) -> [Suntime] {
        
        let ss = EDSunriseSet(timezone: timezone, latitude: location.latitude, longitude: location.longitude)
        
        ss.calculateTwilight(date)
        ss.calculateSunriseSunset(date)
        
        let suntimes: [Suntime] = suntypes.map { type in
            return Suntime(type: type)
        }
        
        // Astronomical
        let astronomicalNever = neverHappens(ss.astronomicalTwilightEnd, date2: ss.astronomicalTwilightStart)
        suntimes[0].date = ss.astronomicalTwilightEnd
        suntimes[0].neverHappens = astronomicalNever
        suntimes[7].date = ss.astronomicalTwilightStart
        suntimes[7].neverHappens = astronomicalNever
        
        // Nautical
        let nauticalNever = neverHappens(ss.nauticalTwilightStart, date2: ss.nauticalTwilightEnd)
        suntimes[1].date = ss.nauticalTwilightEnd
        suntimes[1].neverHappens = nauticalNever
        suntimes[6].date = ss.nauticalTwilightStart
        suntimes[6].neverHappens = nauticalNever
        
        // Civil
        let civilNever = neverHappens(ss.civilTwilightStart, date2: ss.civilTwilightEnd)
        suntimes[2].date = ss.civilTwilightEnd
        suntimes[2].neverHappens = civilNever
        suntimes[5].date = ss.civilTwilightStart
        suntimes[5].neverHappens = civilNever
        
        // Rise/Set
        let riseSetNever = neverHappens(ss.sunrise, date2: ss.sunset)
        suntimes[3].date = ss.sunrise
        suntimes[3].neverHappens = riseSetNever
        suntimes[4].date = ss.sunset
        suntimes[4].neverHappens = riseSetNever

        return suntimes
    }
}