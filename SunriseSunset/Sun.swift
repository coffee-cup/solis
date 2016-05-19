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
    
    let screenMinutes: Float
    var screenHeight: Float
    var sunHeight: Float
    var sunViewScale: Float
    var sunView: UIView
    var gradientLayer: CAGradientLayer
    
    var now: NSDate = NSDate()
    var location: CLLocationCoordinate2D!
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    var suntimes: [Suntime] = []
    
    init(screenMinutes: Float, screenHeight: Float, sunHeight: Float, sunViewScale: Float, sunView: UIView, gradientLayer: CAGradientLayer) {
        self.screenMinutes = screenMinutes
        self.screenHeight = screenHeight
        self.sunHeight = sunHeight
        self.sunViewScale = sunViewScale
        self.sunView = sunView
        self.gradientLayer = gradientLayer
        
        calendar.timeZone = NSTimeZone.localTimeZone()
    }
    
    func update(offset: Float, location: CLLocationCoordinate2D) {
        findNow(offset)
        calculateSunriseSunset(location)
        calculateGradient()
    }
    
    func findNow(offset: Float) {
        now = NSDate().dateByAddingTimeInterval(Double(offset))
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d HH:mm"
        print("\(formatter.stringFromDate(now))")
    }
    
    func calculateAllTimes(date: NSDate) {
        let timeZone = NSTimeZone.localTimeZone()
        let ss = EDSunriseSet(timezone: timeZone, latitude: location.latitude, longitude: location.longitude)
        ss.calculateTwilight(date)
        ss.calculateSunriseSunset(date)
        
        suntimes.append(Suntime(day: date, dateComponents: ss.localAstronomicalTwilightStart(), type: .AstronomicalDusk))
        suntimes.append(Suntime(day: date, dateComponents: ss.localNauticalCivilTwilightStart(), type: .NauticalDusk))
        suntimes.append(Suntime(day: date, dateComponents: ss.localCivilTwilightStart(), type: .CivilDusk))
        suntimes.append(Suntime(day: date, dateComponents: ss.localSunrise(), type: .Sunrise))
        suntimes.append(Suntime(day: date, dateComponents: ss.localSunset(), type: .Sunset))
        suntimes.append(Suntime(day: date, dateComponents: ss.localCivilTwilightEnd(), type: .CivilTwilight))
        suntimes.append(Suntime(day: date, dateComponents: ss.localNauticalCivilTwilightEnd(), type: .NauticalTwilight))
        suntimes.append(Suntime(day: date, dateComponents: ss.localAstronomicalTwilightEnd(), type: .AstronmicalTwilight))
    }
    
    func calculateSunriseSunset(location: CLLocationCoordinate2D) {
        self.location = location
        
        let today = NSDate()
        let yesterday = calendar.dateByAddingUnit(.Day, value: -1, toDate: today, options: [])!
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        suntimes.removeAll()
        calculateAllTimes(yesterday)
        calculateAllTimes(today)
        calculateAllTimes(tomorrow)
    }
    
    func getDifferenceInMinutes(date1: NSDate, date2: NSDate) -> Int {
        let differenceSeconds = date1.timeIntervalSinceDate(date2)
        return abs(Int(differenceSeconds / 60))
    }
    
    func getGradientPercent(time: Suntime, now: NSDate) -> Float {
        let difference: Int = getDifferenceInMinutes(time.date, date2: now)
        //        print("\(time.type.description) is \(Float(difference) / 60.0) hours away")
        let scaled: Float = Float(difference) / screenMinutes
        let percent: Float = (scaled * screenHeight) / sunHeight
        return percent
    }
    
    func calculateGradient() {
        sunView.backgroundColor = UIColor.clearColor()
        gradientLayer.frame = sunView.bounds
        
        var pastTimes: [Suntime] = []
        var futureTimes: [Suntime] = []
        for time in suntimes {
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
            if time.marker {
                colours.append(time.colour)
                locations.append(per)
            }
        }
        
        for time in pastTimes.reverse() {
            let per = 0.5 + getGradientPercent(time, now: now)
            if time.marker {
                colours.append(time.colour)
                locations.append(per)
            }
        }
        
        animateGradient(gradientLayer, toColours: colours, toLocations: locations)
    }
    
    func animateGradient(gradientLayer: CAGradientLayer, toColours: [CGColorRef], toLocations: [Float]) {
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