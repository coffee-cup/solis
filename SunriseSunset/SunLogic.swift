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
    
    static let suntypes: [SunType] = [.astronomicalDusk, .nauticalDusk, .civilDusk, .sunrise, .sunset, .civilDawn, .nauticalDawn, .astronomicalDawn]
    
    // If there is no physical astronomical/nautical/civil twilight start or end (sun is never 18/16/12 degress below horizon)
    // Then the difference between start and end is a full 24 hours (86400 seconds)
    class func neverHappens(_ date1: Date, date2: Date) -> Bool {
        return abs(date1.timeIntervalSince(date2)) == 86400
    }
    
    class func calculateTimesForDate(_ date: Date, location: CLLocationCoordinate2D, timezone: TimeZone = TimeZone.ReferenceType.local, day: SunDay) -> [Suntime] {
        let ss = EDSunriseSet(timezone: timezone, latitude: location.latitude, longitude: location.longitude)
        
        ss?.calculateTwilight(date)
        ss?.calculateSunriseSunset(date)
        
        let suntimes: [Suntime] = suntypes.map { type in
            return Suntime(type: type, day: day)
        }
        
        // Astronomical
        let astronomicalNever = neverHappens((ss?.astronomicalTwilightEnd)!, date2: (ss?.astronomicalTwilightStart)!)
        suntimes[0].date = ss?.astronomicalTwilightEnd
        suntimes[0].neverHappens = astronomicalNever
        suntimes[7].date = ss?.astronomicalTwilightStart
        suntimes[7].neverHappens = astronomicalNever
        
        // Nautical
        let nauticalNever = neverHappens((ss?.nauticalTwilightStart)!, date2: (ss?.nauticalTwilightEnd)!)
        suntimes[1].date = ss?.nauticalTwilightEnd
        suntimes[1].neverHappens = nauticalNever
        suntimes[6].date = ss?.nauticalTwilightStart
        suntimes[6].neverHappens = nauticalNever
        
        // Civil
        let civilNever = neverHappens((ss?.civilTwilightStart)!, date2: (ss?.civilTwilightEnd)!)
        suntimes[2].date = ss?.civilTwilightEnd
        suntimes[2].neverHappens = civilNever
        suntimes[5].date = ss?.civilTwilightStart
        suntimes[5].neverHappens = civilNever
        
        // Rise/Set
        let riseSetNever = neverHappens((ss?.sunrise)!, date2: (ss?.sunset)!)
        suntimes[3].date = ss?.sunrise
        suntimes[3].neverHappens = riseSetNever
        suntimes[4].date = ss?.sunset
        suntimes[4].neverHappens = riseSetNever

        return suntimes
    }
    
    class func createSuntimeInMiddle(startTime: Suntime, endTime: Suntime) -> Suntime {
        let middleTimeDate = Date.init(timeIntervalSince1970: (endTime.date.timeIntervalSince1970 + startTime.date.timeIntervalSince1970) / 2)
        print("middle time: \(middleTimeDate)")
        
        let middleTime = Suntime(type: .middleNight, day: .today)
        middleTime.date = middleTimeDate
        return middleTime
    }
    
    class func createMiddleLines(_ suntimes: [Suntime]) -> [Suntime] {
        print("\n===== Checking")
        
        
        let nightTypes: [SunType] = [.astronomicalDusk, .nauticalDusk, .civilDusk, .sunset]
        let dayTypes: [SunType] = [.astronomicalDawn, .nauticalDawn, .civilDawn, .sunrise]
        
        guard let nightStartTime1 = SunLogic.getFirstSunType(suntimes, sunTypes: nightTypes, day: .yesterday) else {
            return []
        }
        
        guard let nightEndTime1 = SunLogic.getFirstSunType(suntimes, sunTypes: dayTypes, day: .today) else {
            return []
        }
        
        guard let nightStartTime2 = SunLogic.getFirstSunType(suntimes, sunTypes: nightTypes, day: .today) else {
            return []
        }
        guard let nightEndTime2 = SunLogic.getFirstSunType(suntimes, sunTypes: dayTypes, day: .tomorrow) else {
            return []
        }
        
        return [createSuntimeInMiddle(startTime: nightStartTime1, endTime: nightEndTime1), createSuntimeInMiddle(startTime: nightStartTime2, endTime: nightEndTime2)]
    }
    
    class func todayTomorrow(_ location: CLLocationCoordinate2D) -> [Suntime] {
        let today = Date()
        let tomorrow = today.addDays(1)
        return SunLogic.calculateTimesForDate(today, location: location, day: .today)
            + SunLogic.calculateTimesForDate(tomorrow, location: location, day: .tomorrow)
    }
    
    class func futureTimes(_ suntimes: [Suntime]) -> [Suntime] {
        return suntimes.filter { time in
            return time.date.timeIntervalSinceNow > 0
        }
    }
    
    class func getSunType(_ suntimes: [Suntime], type: SunType, day: SunDay? = nil) -> Suntime? {
        let matches = suntimes.filter { time in
            let m = time.type == type && !time.neverHappens
            if let day = day {
                return m && (time.day == day)
            }
            return m
        }
        let sorted = matches.sorted()
        return sorted.count > 0 ? sorted[0] : nil
    }
    
    class func getFirstSunType(_ suntimes: [Suntime], sunTypes: [SunType], day: SunDay? = nil) -> Suntime? {
        for type in sunTypes {
            if let suntime = getSunType(suntimes, type: type, day: day) {
                return suntime
            }
        }
        return nil
    }
    
    class func getNextSunType(_ suntimes: [Suntime], type: SunType) -> Suntime? {
        let times = futureTimes(suntimes)
        return getSunType(times, type: type)
    }
    
    class func sunrise(_ suntimes: [Suntime]) -> Suntime? {
        return getNextSunType(suntimes, type: .sunrise)
    }
    
    class func sunset(_ suntimes: [Suntime]) -> Suntime? {
        return getNextSunType(suntimes, type: .sunset)
    }
    
    class func firstLight(_ suntimes: [Suntime]) -> Suntime? {
        let types: [SunType] = [.astronomicalDawn, .nauticalDawn, .civilDawn]
        for type in types {
            if let time = getNextSunType(suntimes, type: type) {
                return time
            }
        }
        return nil
    }
    
    class func lastLight(_ suntimes: [Suntime]) -> Suntime? {
        let types: [SunType] = [.astronomicalDusk, .nauticalDusk, .civilDusk]
        for type in types {
            if let time = getNextSunType(suntimes, type: type) {
                return time
            }
        }
        return nil
    }
    
    class func nextEvent(_ suntimes: [Suntime]) -> Suntime? {
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
        
        let sortedEvents = possibleEvents.sorted()
        if sortedEvents.count > 0 {
            return sortedEvents[0]
        }
        return nil
    }
}
