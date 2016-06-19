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
    
    class func todayTomorrow(location: CLLocationCoordinate2D) -> [Suntime] {
        let today = NSDate()
        let tomorrow = today.addDays(1)
        return SunLogic.calculateTimesForDate(today, location: location)
            + SunLogic.calculateTimesForDate(tomorrow, location: location)
    }
    
    class func futureTimes(suntimes: [Suntime]) -> [Suntime] {
        return suntimes.filter { time in
            return time.date.timeIntervalSinceNow > 0
        }
    }
    
    class func getNextSunType(suntimes: [Suntime], type: SunType) -> Suntime? {
        let times = futureTimes(suntimes)
        let matches = times.filter { time in
            return time.type == type && !time.neverHappens
        }
        let sorted = matches.sort()
        return sorted.count > 0 ? sorted[0] : nil
    }
    
    class func sunrise(suntimes: [Suntime]) -> Suntime? {
        return getNextSunType(suntimes, type: .Sunrise)
    }
    
    class func sunset(suntimes: [Suntime]) -> Suntime? {
        return getNextSunType(suntimes, type: .Sunset)
    }
    
    class func firstLight(suntimes: [Suntime]) -> Suntime? {
        let types: [SunType] = [.AstronomicalDawn, .NauticalDawn, .CivilDawn]
        for type in types {
            if let time = getNextSunType(suntimes, type: type) {
                return time
            }
        }
        return nil
    }
    
    class func lastLight(suntimes: [Suntime]) -> Suntime? {
        let types: [SunType] = [.AstronomicalDusk, .NauticalDusk, .CivilDusk]
        for type in types {
            if let time = getNextSunType(suntimes, type: type) {
                return time
            }
        }
        return nil
    }
    
    class func nextEvent(suntimes: [Suntime]) -> Suntime? {
        var possibleEvents: [Suntime] = []
        
        if let firstLight = firstLight(suntimes) {
            possibleEvents.append(firstLight)
        }
        if let sunset = sunset(suntimes) {
            possibleEvents.append(sunset)
        }
        if let sunrise = sunrise(suntimes) {
            possibleEvents.append(sunrise)
        }
        if let lastLight = lastLight(suntimes) {
            possibleEvents.append(lastLight)
        }
        
        let sortedEvents = possibleEvents.sort()
        if sortedEvents.count > 0 {
            return sortedEvents[0]
        }
        return nil
    }
}