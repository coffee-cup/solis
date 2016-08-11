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

struct SunTimeMarker: Comparable {
    var sunTimeLine: SunTimeLine
    var percent: Float
    
    init(sunTimeLine: SunTimeLine, percent: Float) {
        self.sunTimeLine = sunTimeLine
        self.percent = percent
    }
}

func < (lhs: SunTimeMarker, rhs: SunTimeMarker) -> Bool {
    return lhs.sunTimeLine.suntime < rhs.sunTimeLine.suntime
}

func == (lhs: SunTimeMarker, rhs: SunTimeMarker) -> Bool {
    return lhs.sunTimeLine.suntime == rhs.sunTimeLine.suntime
}

protocol SunProtocol {
    func collisionIsHappening()
    func collisionNotHappening()
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
    
    // The label for displaying current time
    var nowTimeLabel: UILabel
    
    // The label for displaying "now" text
    var nowLabel: UILabel
    
    // Formatter for now label text
    let nowTextFormatter = NSDateFormatter()
    
    var offset: NSTimeInterval = 0
    
    // Whether or not the sun areas or visible
    var sunAreasVisible = true
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var now: NSDate = NSDate()
    var location: CLLocationCoordinate2D!
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    
    var delegate: SunProtocol?
    
//    var suntimes: [Suntime] = []
//    var sunlines: [Sunline] = []
    var sunTimeLines: [SunTimeLine] = []
    var sunAreas: [SunArea] = []
    
    init(screenMinutes: Float, screenHeight: Float, sunHeight: Float, sunView: UIView, gradientLayer: CAGradientLayer, nowTimeLabel: UILabel, nowLabel: UILabel) {
        self.screenMinutes = screenMinutes
        self.screenHeight = screenHeight
        self.sunHeight = sunHeight
        self.sunViewScale = Float(Float(sunHeight) / Float(screenHeight))
        self.sunView = sunView
        self.gradientLayer = gradientLayer
        self.nowTimeLabel = nowTimeLabel
        self.nowLabel = nowLabel
        
        gradientLayer.frame = sunView.bounds
        
        nowTextFormatter.dateFormat = "MMMM d"
        
        timeFormatUpdate()
        
        calendar.timeZone = NSTimeZone.localTimeZone()
        
        createSunAreas()
        
        for dayNumber in 1...3 {
            createSuntime(.AstronomicalDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.NauticalDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.CivilDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.Sunrise, view: sunView, dayNumber: dayNumber)
            createSuntime(.Sunset, view: sunView, dayNumber: dayNumber)
            createSuntime(.CivilDawn, view: sunView, dayNumber: dayNumber)
            createSuntime(.NauticalDawn, view: sunView, dayNumber: dayNumber)
            createSuntime(.AstronomicalDawn, view: sunView, dayNumber: dayNumber)
        }
        
        Bus.subscribeEvent(.TimeFormat, observer: self, selector: #selector(timeFormatUpdate))
    }
    
    func createSuntime(type: SunType, view: UIView, dayNumber: Int) {
        var day: SunDay!
        if dayNumber == 1 {
            day = .Yesterday
        } else if dayNumber == 2 {
            day = .Today
        } else if dayNumber == 3 {
            day = .Tomorrow
        }
        
        let suntime = Suntime(type: type, day: day)
        let sunline = Sunline()
        sunline.createLine(view, type: type)
        
        sunTimeLines.append(SunTimeLine(suntime: suntime, sunline: sunline))
    }
    
    func createGoldenHourArea(day: SunDay, inMorning: Bool) -> SunArea {
        let startDegrees: Float = -6
        let endDegrees: Float = 4
        
        var colours = [
            goldenHourColour.colorWithAlphaComponent(0).CGColor,
            goldenHourColour.colorWithAlphaComponent(0.2).CGColor,
            goldenHourColour.CGColor,
            blueHourColour.colorWithAlphaComponent(0.2).CGColor
        ]
        if !inMorning {
            colours = colours.reverse()
        }
        
        let locations: [Float] = inMorning ? [
            0,
            0.4,
            0.8,
            1
        ] : [
            0,
            0.2,
            0.6,
            1
        ]
        
        let goldenHourArea = SunArea(
            startDegrees: startDegrees,
            endDegrees: endDegrees,
            name: "golden hour",
            colour: goldenHourColour,
            day: day,
            inMorning: inMorning)
        
        goldenHourArea.colours = colours
        goldenHourArea.locations = locations
        goldenHourArea.createArea(sunView)
        return goldenHourArea
    }
    
    func createBlueHourArea(day: SunDay, inMorning: Bool) -> SunArea {
        let startDegrees: Float = 4
        let endDegrees: Float = 6
        
        var colours = [
            blueHourColour.colorWithAlphaComponent(0.2).CGColor,
            blueHourColour.CGColor,
            blueHourColour.colorWithAlphaComponent(0.1).CGColor,
            blueHourColour.colorWithAlphaComponent(0).CGColor
        ]
        if !inMorning {
           colours = colours.reverse()
        }
        
        let locations: [Float] = inMorning ? [
            0,
            0.4,
            0.8,
            1
        ] : [
            0,
            0.2,
            0.6,
            1
        ]
        
        let blueHourArea = SunArea(
            startDegrees: startDegrees,
            endDegrees: endDegrees,
            name: "blue hour",
            colour: blueHourColour,
            day: day,
            inMorning: inMorning)
        
        blueHourArea.colours = colours
        blueHourArea.locations = locations
        blueHourArea.createArea(sunView)
        return blueHourArea
    }
    
    func createSunAreas() {
        // Evening Golden Hour
//        sunAreas.append(createGoldenHourArea(.Yesterday, inMorning: false))
        sunAreas.append(createGoldenHourArea(.Today, inMorning: false))
//        sunAreas.append(createGoldenHourArea(.Tomorrow, inMorning: false))

        // Morning Golden Hour
//        sunAreas.append(createGoldenHourArea(.Yesterday, inMorning: true))
//        sunAreas.append(createGoldenHourArea(.Today, inMorning: true))
        sunAreas.append(createGoldenHourArea(.Tomorrow, inMorning: true))

        // Evening Blue Hour
//        sunAreas.append(createBlueHourArea(.Yesterday, inMorning: false))
        sunAreas.append(createBlueHourArea(.Today, inMorning: false))
//        sunAreas.append(createBlueHourArea(.Tomorrow, inMorning: false))

        // Morning Blue Hour
//        sunAreas.append(createBlueHourArea(.Yesterday, inMorning: true))
//        sunAreas.append(createBlueHourArea(.Today, inMorning: true))
        sunAreas.append(createBlueHourArea(.Tomorrow, inMorning: true))
    }
    
    func toggleSunAreas() {
        sunAreasVisible = !sunAreasVisible
        for sunArea in sunAreas {
            sunAreasVisible ?
                sunArea.fadeInView() :
                sunArea.fadeOutView()
        }
    }
    
    @objc func timeFormatUpdate() {
        setSunlineTimes()
        setNowTimeText()
    }
    
    func setSunlineTimes() {
        var colliding = false
        for stl in sunTimeLines {
            colliding = stl.sunline.updateTime(offset) || colliding
        }
        colliding ? delegate?.collisionIsHappening() : delegate?.collisionNotHappening()
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
        
        if offset == 0 {
            nowLabel.text = "now"
        } else {
            nowLabel.text = nowTextFormatter.stringFromDate(now)
        }
    }
    
    func update(offset: Double, location: CLLocationCoordinate2D) {
        calculateSunriseSunset(location)
        calculateGradient()
        findNow(offset)
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
        self.setSunlineTimes()
    }
    
    func calculateSunriseSunset(location: CLLocationCoordinate2D) {
        self.location = location
        
        let today = NSDate()
        let yesterday = calendar.dateByAddingUnit(.Day, value: -1, toDate: today, options: [])!
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: today, options: [])!
        
        let suntimes = SunLogic.calculateTimesForDate(yesterday, location: location, day: .Yesterday)
            + SunLogic.calculateTimesForDate(today, location: location, day: .Today)
            + SunLogic.calculateTimesForDate(tomorrow, location: location, day: .Tomorrow)
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
        
        var sunTimeMarkers: [SunTimeMarker] = []
        var colours: [CGColorRef] = []
//        var locations: [Float] = []
        
        var lowestStl: SunTimeLine!
        var lowestLocation: Float = -Float.infinity
        var lowestColour: CGColorRef?
        for stl in futureTimeLines.reverse() {
            let per = 0.5  - getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                sunTimeMarkers.append(SunTimeMarker(sunTimeLine: stl, percent: per))
                colours.append(stl.suntime.colour)
//                locations.append(per)
            }
            if per < 0 && per > lowestLocation && !stl.suntime.neverHappens {
                lowestLocation = per
                lowestColour = stl.suntime.colour
                lowestStl = stl
            }
            stl.sunline.updateLine(stl.suntime.date, percent: per, happens: !stl.suntime.neverHappens)
        }
        if let lowestColour = lowestColour {
            sunTimeMarkers.insert(SunTimeMarker(sunTimeLine: lowestStl, percent: 0), atIndex: 0)
//            locations.insert(0, atIndex: 0)
            colours.insert(lowestColour, atIndex: 0)
        }
        
        var highestStl: SunTimeLine!
        var highestLocation: Float = Float.infinity
        var highestColour: CGColorRef?
        for stl in pastTimeLines.reverse() {
            let per = 0.5 + getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                sunTimeMarkers.append(SunTimeMarker(sunTimeLine: stl, percent: per))
                colours.append(stl.suntime.colour)
//                locations.append(per)
            }
            
            if per > 1 && per < highestLocation && !stl.suntime.neverHappens {
                highestLocation = per
                highestColour = stl.suntime.colour
                highestStl = stl
            }
            stl.sunline.updateLine(stl.suntime.date, percent: per, happens: !stl.suntime.neverHappens)
        }
        if let highestColour = highestColour {
            sunTimeMarkers.append(SunTimeMarker(sunTimeLine: highestStl, percent: 1))
//            locations.append(1)
            colours.append(highestColour)
        }
        
        let locations: [Float] = sunTimeMarkers.map { sunTimeMarker in
            return sunTimeMarker.percent
        }
        animateGradient(gradientLayer, toColours: colours, toLocations: locations)
        
        calculateSunAreas(sunTimeMarkers)
    }
    
    func calculateSunAreas(sunTimeMarkers: [SunTimeMarker]) {
        for sunArea in sunAreas {
            sunArea.updateArea(sunTimeMarkers)
        }
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