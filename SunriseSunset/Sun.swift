//
//  Gradient.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

struct SunTimeLine {
    let suntime: Suntime
    let sunline: Sunline
}

@MainActor
protocol SunProtocol: AnyObject {
    func collisionIsHappening()
    func collisionNotHappening()
}

@MainActor
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

    var now: Date = ScreenshotFixture.now
    var location: CLLocationCoordinate2D!
    var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    weak var delegate: SunProtocol?
    
    var sunTimeLines: [SunTimeLine] = []
    var sunAreas: [SunArea] = []
    private let stateLabel = UILabel()
    private var solarDays: [(SunDay, SolarDay)] = []
    private var calculationKey: String?
    private var bandIntervals: [DateInterval] = []
    
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
        
        stateLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        stateLabel.textColor = nameTextColour
        stateLabel.textAlignment = .right
        stateLabel.numberOfLines = 2
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        if let container = nowTimeLabel.superview {
            container.addSubview(stateLabel)
            NSLayoutConstraint.activate([
                stateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                stateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 110),
                stateLabel.topAnchor.constraint(equalTo: container.centerYAnchor, constant: 8)
            ])
        }

        nowTextFormatter.dateFormat = "MMMM d"
        
        timeFormatUpdate()
        
        calendar.timeZone = TimeZone.ReferenceType.local
        
        
        sunAreasVisible = !Defaults.showSunAreas
        toggleSunAreas()
        
    }

    static func goldenHourColours(inMorning: Bool) -> [CGColor] {
        let colours = [
            goldenHourColour.withAlphaComponent(0).cgColor,
            goldenHourColour.withAlphaComponent(0.2).cgColor,
            goldenHourColour.cgColor,
            blueHourColour.withAlphaComponent(0.2).cgColor
        ]
        return inMorning ? colours : colours.reversed()
    }

    static func blueHourColours(inMorning: Bool) -> [CGColor] {
        let colours = [
            blueHourColour.withAlphaComponent(0.2).cgColor,
            blueHourColour.cgColor,
            blueHourColour.withAlphaComponent(0.1).cgColor,
            blueHourColour.withAlphaComponent(0).cgColor
        ]
        return inMorning ? colours : colours.reversed()
    }

    func createGoldenHourArea(inMorning: Bool) -> SunArea {
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
        
        let goldenHourArea = SunArea(colour: goldenHourColour)
        
        goldenHourArea.colours = Self.goldenHourColours(inMorning: inMorning)
        goldenHourArea.colourBuilder = { Self.goldenHourColours(inMorning: inMorning) }
        goldenHourArea.locations = locations
        goldenHourArea.createArea(sunView)
        return goldenHourArea
    }

    func createBlueHourArea(inMorning: Bool) -> SunArea {
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
        
        let blueHourArea = SunArea(colour: blueHourColour)
        
        blueHourArea.colours = Self.blueHourColours(inMorning: inMorning)
        blueHourArea.colourBuilder = { Self.blueHourColours(inMorning: inMorning) }
        blueHourArea.locations = locations
        blueHourArea.createArea(sunView)
        return blueHourArea
    }

    // Recolours views that cached palette colours at creation. Gradient stops
    // are recomputed by the caller via update().
    func applyTheme() {
        for stl in sunTimeLines {
            stl.sunline.refreshColours()
        }
        for area in sunAreas {
            area.refreshColours()
        }
    }
    
    func toggleSunAreas() {
        sunAreasVisible = !sunAreasVisible
        Defaults.showSunAreas = sunAreasVisible
        for sunArea in sunAreas {
            sunAreasVisible ?
                sunArea.fadeInView() :
                sunArea.fadeOutView()
        }
        layoutSunAreas()
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
        let day = solarDays.first { now >= $0.1.interval.start && now < $0.1.interval.end }?.1
        switch day?.state(at: .horizon) {
        case .above: stateLabel.text = "Sun above the horizon all day"
        case .below: stateLabel.text = "Sun below the horizon all day"
        default: stateLabel.text = nil
        }
        if let formatter = TimeFormatters.currentFormatter(SunLocation.currentTimeZone) {
            nowTimeLabel.text = formatter.string(from: now)
                .replacingOccurrences(of: "AM", with: "am")
                .replacingOccurrences(of: "PM", with: "pm")
        } else {
            nowTimeLabel.text = TimeFormatters.formatter12h(SunLocation.currentTimeZone).string(from: now)
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
        findNow(offset)
        calculateSunriseSunset(location)
        calculateGradient()
        setNowTimeText()
        setSunlineTimes()
    }
    
    func pointsToMinutes(_ points: Double) -> Double {
        let scale = points / Double(screenHeight)
        return scale * Double(screenMinutes)
    }
    
    // offset is in minutes
    func findNow(_ offset: Double) {
        self.offset = offset * 60
        self.now = ScreenshotFixture.now.addingTimeInterval(offset * 60)
        self.setNowTimeText()
        self.setSunlineTimes()
    }
    
    func calculateSunriseSunset(_ location: CLLocationCoordinate2D) {
        self.location = location
        calendar.timeZone = SunLocation.currentTimeZone
        nowTextFormatter.timeZone = calendar.timeZone
        let today = ScreenshotFixture.now
        let key = "\(calendar.startOfDay(for: today).timeIntervalSince1970)|\(location.latitude)|\(location.longitude)|\(calendar.timeZone.identifier)"
        guard key != calculationKey else { return }
        calculationKey = key
        solarDays = SunLogic.window(from: today, location: location, timezone: calendar.timeZone)
        let times = solarDays.flatMap { SunLogic.times(for: $0.1, day: $0.0) }
        // Rebuild the small view collection only when the place or civil day changes.
        // Variable event counts must never truncate the next location's timeline.
        sunTimeLines.forEach { $0.sunline.removeFromSuperview() }
        sunTimeLines = times.map { time in
            let line = Sunline()
            line.createLine(sunView, type: time.type)
            return SunTimeLine(suntime: time, sunline: line)
        }
        sunAreas.forEach { $0.removeFromSuperview() }
        sunAreas = []
        bandIntervals = []
        for (_, solar) in solarDays {
            for golden in [true, false] {
                let intervals = golden ? solar.intervals(between: .blue, and: .golden) : solar.intervals(between: .civil, and: .blue)
                for interval in intervals {
                    let first = SolarPosition.altitude(at: interval.start, latitude: location.latitude, longitude: location.longitude)
                    let last = SolarPosition.altitude(at: interval.end, latitude: location.latitude, longitude: location.longitude)
                    let morning = last > first
                    let area = golden ? createGoldenHourArea(inMorning: morning) : createBlueHourArea(inMorning: morning)
                    sunAreas.append(area)
                    bandIntervals.append(interval)
                }
            }
        }
        sunTimeLines.forEach { sunView.bringSubviewToFront($0.sunline) }
    }

    func calculateGradient() {
        let anchor = ScreenshotFixture.now
        func position(_ date: Date) -> Float {
            0.5 - Float(date.timeIntervalSince(anchor) / 60) / screenMinutes * screenHeight / sunHeight
        }
        for line in sunTimeLines {
            line.sunline.updateLine(line.suntime.date, percent: position(line.suntime.date), happens: true)
        }
        var stops: [(Date, CGColor)] = []
        for (_, solar) in solarDays {
            stops.append((solar.interval.start, SunLogic.skyType(altitude: solar.initialAltitude).colour))
            stops += solar.events.compactMap { event in
                SunLogic.type(for: event).map { (event.date, $0.colour) }
            }
        }
        stops.sort { $0.0 > $1.0 }
        var visible = stops.filter { (0...1).contains(position($0.0)) }.map { (position($0.0), $0.1) }
        let upper = stops.last { position($0.0) < 0 }?.1 ?? stops.first?.1 ?? astronomicalColour.cgColor
        let lower = stops.first { position($0.0) > 1 }?.1 ?? stops.last?.1 ?? astronomicalColour.cgColor
        visible.insert((0, upper), at: 0)
        visible.append((1, lower))
        animateGradient(gradientLayer, toColours: visible.map { $0.1 }, toLocations: visible.map { $0.0 })
        layoutSunAreas()
    }

    private func layoutSunAreas() {
        let anchor = ScreenshotFixture.now
        func position(_ date: Date) -> Float {
            0.5 - Float(date.timeIntervalSince(anchor) / 60) / screenMinutes * screenHeight / sunHeight
        }
        for (area, band) in zip(sunAreas, bandIntervals) {
            let top = max(0, position(band.end)), bottom = min(1, position(band.start))
            let visible = sunAreasVisible && bottom > top
            area.isHidden = !visible
            if visible { area.updateAreaWithPercents(top, maxPercent: bottom) }
        }
    }

    func animateGradient(_ gradientLayer: CAGradientLayer, toColours: [CGColor], toLocations: [Float]) {
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
        colourAnimation.fillMode = CAMediaTimingFillMode.forwards
        colourAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

        locationAnimation.fromValue = fromLocations
        locationAnimation.toValue = toLocations
        locationAnimation.duration = duration
        locationAnimation.isRemovedOnCompletion = true
        locationAnimation.fillMode = CAMediaTimingFillMode.forwards
        locationAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

        gradientLayer.add(colourAnimation, forKey: "animateGradientColour")
        gradientLayer.add(locationAnimation, forKey: "animateGradientLocation")
    }
    
}
