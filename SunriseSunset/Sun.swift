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
        
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        for _ in 1...3 {
            suntimes.append(Suntime(type: .AstronomicalDusk, view: sunView))
            suntimes.append(Suntime(type: .NauticalDusk, view: sunView))
            suntimes.append(Suntime(type: .CivilDusk, view: sunView))
            suntimes.append(Suntime(type: .Sunrise, view: sunView))
            suntimes.append(Suntime(type: .Sunset, view: sunView))
            suntimes.append(Suntime(type: .CivilTwilight, view: sunView))
            suntimes.append(Suntime(type: .NauticalTwilight, view: sunView))
            suntimes.append(Suntime(type: .AstronmicalTwilight, view: sunView))
        }
    }
    
    func update(offset: Float, location: CLLocationCoordinate2D) {
        findNow(offset)
        calculateSunriseSunset(location)
        calculateGradient()
    }
    
    func findNow(offset: Float) {
        now = NSDate().dateByAddingTimeInterval(Double(offset))
        nowTimeLabel.text = Sun.timeFormatter.stringFromDate(now)
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d HH:mm"
        print("\(formatter.stringFromDate(now))")
    }
    
    func calculateAllTimes(date: NSDate, set: Int) {
        let timeZone = NSTimeZone.localTimeZone()
        let ss = EDSunriseSet(timezone: timeZone, latitude: location.latitude, longitude: location.longitude)
        ss.calculateTwilight(date)
        ss.calculateSunriseSunset(date)
        
        let off = set * 8
        suntimes[0 + off].setValues(date, dateComponents: ss.localAstronomicalTwilightStart())
        suntimes[1 + off].setValues(date, dateComponents: ss.localNauticalCivilTwilightStart())
        suntimes[2 + off].setValues(date, dateComponents: ss.localCivilTwilightStart())
        suntimes[3 + off].setValues(date, dateComponents: ss.localSunrise())
        suntimes[4 + off].setValues(date, dateComponents: ss.localSunset())
        suntimes[5 + off].setValues(date, dateComponents: ss.localCivilTwilightEnd())
        suntimes[6 + off].setValues(date, dateComponents: ss.localNauticalCivilTwilightEnd())
        suntimes[7 + off].setValues(date, dateComponents: ss.localAstronomicalTwilightEnd())
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
            time.sunline.updateLine(time.date, percent: per)
        }
        
        for time in pastTimes.reverse() {
            let per = 0.5 + getGradientPercent(time, now: now)
            if time.marker {
                colours.append(time.colour)
                locations.append(per)
            }
            time.sunline.updateLine(time.date, percent: per)
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