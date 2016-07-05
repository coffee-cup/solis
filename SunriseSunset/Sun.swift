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

struct SunTimeLine: Comparable {
    var suntime: Suntime
    var sunline: Sunline
    
    init(suntime: Suntime, sunline: Sunline) {
        self.suntime = suntime
        self.sunline = sunline
    }
}

func < (lhs: SunTimeLine, rhs: SunTimeLine) -> Bool {
    return lhs.suntime < rhs.suntime
}

func == (lhs: SunTimeLine, rhs: SunTimeLine) -> Bool {
    return lhs.suntime == rhs.suntime
}

class Sun {
    
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
    
//    var suntimes: [Suntime] = []
//    var sunlines: [Sunline] = []
    var sunTimeLines: [SunTimeLine] = []
    
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
            createSuntime(.AstronomicalDusk, view: sunView)
            createSuntime(.NauticalDusk, view: sunView)
            createSuntime(.CivilDusk, view: sunView)
            createSuntime(.Sunrise, view: sunView)
            createSuntime(.Sunset, view: sunView)
            createSuntime(.CivilDawn, view: sunView)
            createSuntime(.NauticalDawn, view: sunView)
            createSuntime(.AstronomicalDawn, view: sunView)
        }
        
        Bus.subscribeEvent(.TimeFormat, observer: self, selector: #selector(timeFormatUpdate))
    }
    
    func createSuntime(type: SunType, view: UIView) {
        let suntime = Suntime(type: type)
        let sunline = Sunline()
        sunline.createLine(view, type: type)
        
        sunTimeLines.append(SunTimeLine(suntime: suntime, sunline: sunline))
    }
    
    @objc func timeFormatUpdate() {
        setSunlineTimes()
        setNowTimeText()
    }
    
    func setSunlineTimes() {
        for stl in sunTimeLines {
            stl.sunline.updateTime(-1 * offset)
        }
    }
    
    func setNowTimeText() {
        if let formatter = TimeFormatters.currentFormatter(TimeZones.currentTimeZone) {
            nowTimeLabel.text = formatter.stringFromDate(now)
                .stringByReplacingOccurrencesOfString("AM", withString: "am")
                .stringByReplacingOccurrencesOfString("PM", withString: "pm")
        } else {
            nowTimeLabel.text = TimeFormatters.formatter12h(TimeZones.currentTimeZone).stringFromDate(now)
                .stringByReplacingOccurrencesOfString("AM", withString: "am")
                .stringByReplacingOccurrencesOfString("PM", withString: "pm")
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
    
    func calculateSunriseSunset(location: CLLocationCoordinate2D) {
        self.location = location
        
        let today = NSDate()
        let yesterday = calendar.dateByAddingUnit(.Day, value: -1, toDate: today, options: [])!
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        let suntimes = SunLogic.calculateTimesForDate(yesterday, location: location)
            + SunLogic.calculateTimesForDate(today, location: location)
            + SunLogic.calculateTimesForDate(tomorrow, location: location)
        for (index, time) in suntimes.enumerate() {
            sunTimeLines[index].suntime = time
        }
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

        let sortedFiltered = sunTimeLines.sort()
        
        var pastTimeLines: [SunTimeLine] = []
        var futureTimeLines: [SunTimeLine] = []
        for stl in sortedFiltered {
            if stl.suntime.date.isLessThanDate(now) {
                pastTimeLines.append(stl)
            } else {
                futureTimeLines.append(stl)
            }
        }
        
        var colours: [CGColorRef] = []
        var locations: [Float] = []
        
        var lowestLocation: Float = -Float.infinity
        var lowestColour: CGColorRef?
        for stl in futureTimeLines.reverse() {
            let per = 0.5  - getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                colours.append(stl.suntime.colour)
                locations.append(per)
            }
            if per < 0 && per > lowestLocation {
                lowestLocation = per
                lowestColour = stl.suntime.colour
            }
            stl.sunline.updateLine(stl.suntime.date, percent: per, happens: !stl.suntime.neverHappens)
        }
        if let lowestColour = lowestColour {
            locations.insert(0, atIndex: 0)
            colours.insert(lowestColour, atIndex: 0)
        }
        
        var highestLocation: Float = Float.infinity
        var highestColour: CGColorRef?
        for stl in pastTimeLines.reverse() {
            let per = 0.5 + getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                colours.append(stl.suntime.colour)
                locations.append(per)
            }
            
            if per > 1 && per < highestLocation {
                highestLocation = per
                highestColour = stl.suntime.colour
            }
            stl.sunline.updateLine(stl.suntime.date, percent: per, happens: !stl.suntime.neverHappens)
        }
        if let highestColour = highestColour {
            locations.append(1)
            colours.append(highestColour)
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