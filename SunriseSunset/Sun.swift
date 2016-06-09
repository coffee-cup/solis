//
//  Gradient.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
import EDSunriseSet
import CoreLocation

class Sun {
    
    static let timeFormatter = NSDateFormatter()
    static var delta = false
    
    // Number of minutes a full screen height is
    let screenMinutes: Float
    
    // Height of the screen
    var screenHeight: Float
    
    // Height of the view where the gradient lives
    var sunHeight: Float
    
    // Ratio between screen height and sun view
    var sunViewScale: Float
    
    // View where the gradient lives
    var sunView: UIView
    
    // Gradient that animates to show time of day
    var gradientLayer: CAGradientLayer
    
    var nowTimeLabel: UILabel
    
    var offset: NSTimeInterval = 0
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var now: NSDate = NSDate()
    var location: CLLocationCoordinate2D!
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    var suntimes: [Suntime] = []
    
    init(screenMinutes: Float, screenHeight: Float, sunHeight: Float, sunView: UIView, gradientLayer: CAGradientLayer, nowTimeLabel: UILabel) {
        self.screenMinutes = screenMinutes
        self.screenHeight = screenHeight
        self.sunHeight = sunHeight
        self.sunViewScale = Float(Float(sunHeight) / Float(screenHeight))
        self.sunView = sunView
        self.gradientLayer = gradientLayer
        self.nowTimeLabel = nowTimeLabel
        
        timeFormatUpdate()
        
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        for _ in 1...3 {
            suntimes.append(Suntime(type: .AstronomicalDusk, view: sunView))
            suntimes.append(Suntime(type: .NauticalDusk, view: sunView))
            suntimes.append(Suntime(type: .CivilDusk, view: sunView))
            suntimes.append(Suntime(type: .Sunrise, view: sunView))
            suntimes.append(Suntime(type: .Sunset, view: sunView))
            suntimes.append(Suntime(type: .CivilDawn, view: sunView))
            suntimes.append(Suntime(type: .NauticalDawn, view: sunView))
            suntimes.append(Suntime(type: .AstronomicalDawn, view: sunView))
        }
        
        Bus.subscribeEvent(.TimeFormat, observer: self, selector: #selector(timeFormatUpdate))
    }
    
    @objc func timeFormatUpdate() {
        let timeFormat = defaults.stringForKey(MessageType.TimeFormat.description)
        if timeFormat == "delta" {
            Sun.delta = true
        } else {
            Sun.delta = false
            Sun.timeFormatter.dateFormat = timeFormat
        }
        setSunlineTimes()
        setNowTimeText()
    }
    
    func setSunlineTimes() {
        for time in suntimes {
            time.sunline.updateTime(-1 * offset)
        }
    }
    
    func setNowTimeText() {
        dispatch_async(dispatch_get_main_queue()) {
            var timeFormat = Sun.timeFormatter.dateFormat
            if Sun.delta {
                timeFormat = TimeFormat.hour12.description
            }
            let formatter = NSDateFormatter()
            formatter.dateFormat = timeFormat
            self.nowTimeLabel.text = formatter.stringFromDate(self.now)
                .stringByReplacingOccurrencesOfString("PM", withString: "pm")
                .stringByReplacingOccurrencesOfString("AM", withString: "am")
        }
    }
    
    func update(offset: Double, location: CLLocationCoordinate2D) {
        findNow(offset)
        calculateSunriseSunset(location)
        calculateGradient()
    }
    
    func pointsToMinutes(points: Double) -> Double {
        let scale = points / Double(screenHeight)
        return scale * Double(screenMinutes)
    }
    
    // offset is in minutes
    func findNow(offset: Double) {
        self.offset = offset * 60
        self.now = NSDate().dateByAddingTimeInterval(offset * 60)
        self.setNowTimeText()
//        self.setSunlineTimes()
    }
    
    // If there is no physical astronomical/nautical/civil twilight start or end (sun is never 18/16/12 degress below horizon)
    // Then the difference between start and end is a full 24 hours (86400 seconds)
    func neverHappens(date1: NSDate, date2: NSDate) -> Bool {
        return abs(date1.timeIntervalSinceDate(date2)) == 86400
    }
    
    func calculateAllTimes(date: NSDate, set: Int) {
        let timeZone = NSTimeZone.localTimeZone()
        let ss = EDSunriseSet(timezone: timeZone, latitude: location.latitude, longitude: location.longitude)
        ss.calculateTwilight(date)
        ss.calculateSunriseSunset(date)
        
        let off = set * 8
        
        // Astronomical
        let astronomicalNever = neverHappens(ss.astronomicalTwilightEnd, date2: ss.astronomicalTwilightStart)
        suntimes[0 + off].date = ss.astronomicalTwilightEnd
        suntimes[0 + off].neverHappens = astronomicalNever
        suntimes[7 + off].date = ss.astronomicalTwilightStart
        suntimes[7 + off].neverHappens = astronomicalNever
        
        // Nautical
        let nauticalNever = neverHappens(ss.nauticalTwilightStart, date2: ss.nauticalTwilightEnd)
        suntimes[1 + off].date = ss.nauticalTwilightEnd
        suntimes[1 + off].neverHappens = nauticalNever
        suntimes[6 + off].date = ss.nauticalTwilightStart
        suntimes[6 + off].neverHappens = nauticalNever
        
        // Civil
        let civilNever = neverHappens(ss.civilTwilightStart, date2: ss.civilTwilightEnd)
        suntimes[2 + off].date = ss.civilTwilightEnd
        suntimes[2 + off].neverHappens = civilNever
        suntimes[5 + off].date = ss.civilTwilightStart
        suntimes[5 + off].neverHappens = civilNever
        
        // Rise/Set
        let riseSetNever = neverHappens(ss.sunrise, date2: ss.sunset)
        suntimes[3 + off].date = ss.sunrise
        suntimes[3 + off].neverHappens = riseSetNever
        suntimes[4 + off].date = ss.sunset
        suntimes[4 + off].neverHappens = riseSetNever
    }
    
    func calculateSunriseSunset(location: CLLocationCoordinate2D) {
        self.location = location
        
        let today = NSDate()
        let yesterday = calendar.dateByAddingUnit(.Day, value: -1, toDate: today, options: [])!
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        calculateAllTimes(yesterday, set: 0)
        calculateAllTimes(today, set: 1)
        calculateAllTimes(tomorrow, set: 2)
    }
    
    func getDifferenceInMinutes(date1: NSDate, date2: NSDate) -> Int {
        let differenceSeconds = date1.timeIntervalSinceDate(date2)
        return abs(Int(differenceSeconds / 60))
    }
    
    func getGradientPercent(time: Suntime, now: NSDate) -> Float {
        let difference: Int = getDifferenceInMinutes(time.date, date2: now)
        let scaled: Float = Float(difference) / screenMinutes
        let percent: Float = (scaled * screenHeight) / sunHeight
        return percent
    }
    
    func calculateGradient() {
        sunView.backgroundColor = UIColor.clearColor()
        gradientLayer.frame = sunView.bounds
        
        let sorted = suntimes.sort() { st1, st2 in
            return st1.date.isLessThanDate(st2.date)
        }
        let filtered = sorted.filter() { time in
            return !time.neverHappens
        }
        
        var pastTimes: [Suntime] = []
        var futureTimes: [Suntime] = []
        for time in filtered {
            if time.date!.isLessThanDate(now) {
                pastTimes.append(time)
            } else {
                futureTimes.append(time)
            }
        }
        
        var colours: [CGColorRef] = []
        var locations: [Float] = []
        
        for time in futureTimes.reverse() {
            let per = 0.5  - getGradientPercent(time, now: now)
            if time.marker && per >= 0 && per <= 1 {
                colours.append(time.colour)
                locations.append(per)
            }
            time.sunline.updateLine(time.date, percent: per)
        }
        
        for time in pastTimes.reverse() {
            let per = 0.5 + getGradientPercent(time, now: now)
            if time.marker && per >= 0 && per <= 1  {
                colours.append(time.colour)
                locations.append(per)
            }
            time.sunline.updateLine(time.date, percent: per)
        }
        
        animateGradient(gradientLayer, toColours: colours, toLocations: locations)
    }
    
    func animateGradient(gradientLayer: CAGradientLayer, toColours: [CGColorRef], toLocations: [Float]) {
        
        dispatch_async(dispatch_get_main_queue()) {
            // Do not animate the first gradient
            guard let _ = gradientLayer.colors else {
                gradientLayer.colors = toColours
                gradientLayer.locations = toLocations
                return
            }
            
            let duration: CFTimeInterval = 0.2
            
            let fromColours = gradientLayer.colors!
            let fromLocations = gradientLayer.locations!
            
            gradientLayer.colors = toColours
            gradientLayer.locations = toLocations
            
            let colourAnimation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
            let locationAnimation: CABasicAnimation = CABasicAnimation(keyPath: "locations")
            
            colourAnimation.fromValue = fromColours
            colourAnimation.toValue = toColours
            colourAnimation.duration = duration
            colourAnimation.removedOnCompletion = true
            colourAnimation.fillMode = kCAFillModeForwards
            colourAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            locationAnimation.fromValue = fromLocations
            locationAnimation.toValue = toLocations
            locationAnimation.duration = duration
            locationAnimation.removedOnCompletion = true
            locationAnimation.fillMode = kCAFillModeForwards
            locationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            gradientLayer.addAnimation(colourAnimation, forKey: "animateGradientColour")
            gradientLayer.addAnimation(locationAnimation, forKey: "animateGradientLocation")
        }
    }
    
}