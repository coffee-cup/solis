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
    let nowTextFormatter = DateFormatter()
    
    var offset: TimeInterval = 0
    
    // Whether or not the sun areas or visible
    var sunAreasVisible = true
    
    let defaults = UserDefaults.standard
    var now: Date = Date()
    var location: CLLocationCoordinate2D!
    var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    var delegate: SunProtocol?
    
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
        
        calendar.timeZone = TimeZone.ReferenceType.local
        
        createSunAreas()
        
        sunAreasVisible = !Defaults.showSunAreas
        toggleSunAreas()
        
        for dayNumber in 1...3 {
            createSuntime(.astronomicalDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.nauticalDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.civilDusk, view: sunView, dayNumber: dayNumber)
            createSuntime(.sunrise, view: sunView, dayNumber: dayNumber)
            createSuntime(.sunset, view: sunView, dayNumber: dayNumber)
            createSuntime(.civilDawn, view: sunView, dayNumber: dayNumber)
            createSuntime(.nauticalDawn, view: sunView, dayNumber: dayNumber)
            createSuntime(.astronomicalDawn, view: sunView, dayNumber: dayNumber)
        }
        createSuntime(.middleNight, view: sunView, dayNumber: 2)
        createSuntime(.middleNight, view: sunView, dayNumber: 3)
        
        Bus.subscribeEvent(.timeFormat, observer: self, selector: #selector(timeFormatUpdate))
    }
    
    func createSuntime(_ type: SunType, view: UIView, dayNumber: Int) {
        var day: SunDay!
        if dayNumber == 1 {
            day = .yesterday
        } else if dayNumber == 2 {
            day = .today
        } else if dayNumber == 3 {
            day = .tomorrow
        }
        
        let suntime = Suntime(type: type, day: day)
        let sunline = Sunline()
        sunline.createLine(view, type: type)
        
        sunTimeLines.append(SunTimeLine(suntime: suntime, sunline: sunline))
    }
    
    func createGoldenHourArea(_ day: SunDay, inMorning: Bool) -> SunArea {
        let startDegrees: Float = -6
        let endDegrees: Float = 4
        
        // Carefully fuck with these numbers
        var colours = [
            goldenHourColour.withAlphaComponent(0).cgColor,
            goldenHourColour.withAlphaComponent(0.2).cgColor,
            goldenHourColour.cgColor,
            blueHourColour.withAlphaComponent(0.2).cgColor
        ]
        if !inMorning {
            colours = colours.reversed()
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
    
    func createBlueHourArea(_ day: SunDay, inMorning: Bool) -> SunArea {
        let startDegrees: Float = 4
        let endDegrees: Float = 6
        
        // Carefully fuck with these numbers
        var colours = [
            blueHourColour.withAlphaComponent(0.2).cgColor,
            blueHourColour.cgColor,
            blueHourColour.withAlphaComponent(0.1).cgColor,
            blueHourColour.withAlphaComponent(0).cgColor
        ]
        if !inMorning {
           colours = colours.reversed()
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
        sunAreas.append(createGoldenHourArea(.yesterday, inMorning: false))
        sunAreas.append(createGoldenHourArea(.today, inMorning: false))
        sunAreas.append(createGoldenHourArea(.tomorrow, inMorning: false))

        // Morning Golden Hour
        sunAreas.append(createGoldenHourArea(.yesterday, inMorning: true))
        sunAreas.append(createGoldenHourArea(.today, inMorning: true))
        sunAreas.append(createGoldenHourArea(.tomorrow, inMorning: true))

        // Evening Blue Hour
        sunAreas.append(createBlueHourArea(.yesterday, inMorning: false))
        sunAreas.append(createBlueHourArea(.today, inMorning: false))
        sunAreas.append(createBlueHourArea(.tomorrow, inMorning: false))

        // Morning Blue Hour
        sunAreas.append(createBlueHourArea(.yesterday, inMorning: true))
        sunAreas.append(createBlueHourArea(.today, inMorning: true))
        sunAreas.append(createBlueHourArea(.tomorrow, inMorning: true))
    }
    
    func toggleSunAreas() {
        sunAreasVisible = !sunAreasVisible
        Defaults.showSunAreas = sunAreasVisible
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
            nowTimeLabel.text = formatter.string(from: now)
                .replacingOccurrences(of: "AM", with: "am")
                .replacingOccurrences(of: "PM", with: "pm")
        } else {
            nowTimeLabel.text = TimeFormatters.formatter12h(TimeZones.currentTimeZone).string(from: now)
                .replacingOccurrences(of: "AM", with: "am")
                .replacingOccurrences(of: "PM", with: "pm")
        }
        
        if offset == 0 {
            nowLabel.text = "now"
        } else {
            nowLabel.text = nowTextFormatter.string(from: now)
        }
    }
    
    func update(_ offset: Double, location: CLLocationCoordinate2D) {
        calculateSunriseSunset(location)
        calculateGradient()
        findNow(offset)
    }
    
    func pointsToMinutes(_ points: Double) -> Double {
        let scale = points / Double(screenHeight)
        return scale * Double(screenMinutes)
    }
    
    // offset is in minutes
    func findNow(_ offset: Double) {
        self.offset = offset * 60
        self.now = Date().addingTimeInterval(offset * 60)
        self.setNowTimeText()
        self.setSunlineTimes()
    }
    
    func calculateSunriseSunset(_ location: CLLocationCoordinate2D) {
        self.location = location
        
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        
        var suntimes = SunLogic.calculateTimesForDate(yesterday, location: location, day: .yesterday)
            + SunLogic.calculateTimesForDate(today, location: location, day: .today)
            + SunLogic.calculateTimesForDate(tomorrow, location: location, day: .tomorrow)
          
        suntimes = suntimes + SunLogic.createMiddleLines(suntimes)
        
        for (index, time) in suntimes.enumerated() {
            sunTimeLines[index].suntime = time
        }
        
    }
    
    func getDifferenceInMinutes(_ date1: Date, date2: Date) -> Int {
        let differenceSeconds = date1.timeIntervalSince(date2)
        return abs(Int(differenceSeconds / 60))
    }
    
    func getGradientPercent(_ time: Suntime, now: Date) -> Float {
        let difference: Int = getDifferenceInMinutes(time.date as Date, date2: now)
        let scaled: Float = Float(difference) / screenMinutes
        let percent: Float = (scaled * screenHeight) / sunHeight
        return percent
    }
    
    func calculateGradient() {
        sunView.backgroundColor = UIColor.clear

        let sortedFiltered = sunTimeLines.sorted()
        
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
        var colours: [CGColor] = []
//        var locations: [Float] = []
        
        var lowestStl: SunTimeLine!
        var lowestLocation: Float = -Float.infinity
        var lowestColour: CGColor?
        for stl in futureTimeLines.reversed() {
            let per = 0.5  - getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                sunTimeMarkers.append(SunTimeMarker(sunTimeLine: stl, percent: per))
                colours.append(stl.suntime.colour)
//                locations.append(per)
            }
            if per < 0 && per > lowestLocation && !stl.suntime.neverHappens && stl.suntime.marker {
                lowestLocation = per
                lowestColour = stl.suntime.colour
                lowestStl = stl
            }
            stl.sunline.updateLine(stl.suntime.date, percent: per, happens: !stl.suntime.neverHappens)
        }
        if let lowestColour = lowestColour {
            sunTimeMarkers.insert(SunTimeMarker(sunTimeLine: lowestStl, percent: 0), at: 0)
//            locations.insert(0, atIndex: 0)
            colours.insert(lowestColour, at: 0)
        }
        
        var highestStl: SunTimeLine!
        var highestLocation: Float = Float.infinity
        var highestColour: CGColor?
        for stl in pastTimeLines.reversed() {
            let per = 0.5 + getGradientPercent(stl.suntime, now: now)
            if stl.suntime.marker && !stl.suntime.neverHappens && per >= 0 && per <= 1 {
                sunTimeMarkers.append(SunTimeMarker(sunTimeLine: stl, percent: per))
                colours.append(stl.suntime.colour)
//                locations.append(per)
            }
            
            if per > 1 && per < highestLocation && !stl.suntime.neverHappens && stl.suntime.marker {
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
    
    func calculateSunAreas(_ sunTimeMarkers: [SunTimeMarker]) {
        for sunArea in sunAreas {
            sunArea.updateArea(sunTimeMarkers)
        }
    }
    
    func animateGradient(_ gradientLayer: CAGradientLayer, toColours: [CGColor], toLocations: [Float]) {
        DispatchQueue.main.async {
            // Do not animate the first gradient
            guard let _ = gradientLayer.colors else {
                gradientLayer.colors = toColours
                gradientLayer.locations = toLocations as [NSNumber]?
                return
            }
            
            let duration: CFTimeInterval = 0.2
            
            let fromColours = gradientLayer.colors!
            let fromLocations = gradientLayer.locations!
            
            gradientLayer.colors = toColours
            gradientLayer.locations = toLocations as [NSNumber]?
            
            let colourAnimation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
            let locationAnimation: CABasicAnimation = CABasicAnimation(keyPath: "locations")
            
            colourAnimation.fromValue = fromColours
            colourAnimation.toValue = toColours
            colourAnimation.duration = duration
            colourAnimation.isRemovedOnCompletion = true
            colourAnimation.fillMode = kCAFillModeForwards
            colourAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            locationAnimation.fromValue = fromLocations
            locationAnimation.toValue = toLocations
            locationAnimation.duration = duration
            locationAnimation.isRemovedOnCompletion = true
            locationAnimation.fillMode = kCAFillModeForwards
            locationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            
            gradientLayer.add(colourAnimation, forKey: "animateGradientColour")
            gradientLayer.add(locationAnimation, forKey: "animateGradientLocation")
        }
    }
    
}
