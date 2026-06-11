//
//  SunArea.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-06.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class SunArea: UIView {
    
    var parentView: UIView!
    var nameLabel: UILabel!
    
    var topConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    
    var nameLeftConstraint: NSLayoutConstraint!
    
    var gradientLayer: CAGradientLayer!
    
    var startDegrees: Float!
    var endDegrees: Float!
    var name: String!
    var colour: UIColor!
    
    var colours: [CGColor]?
    var locations: [Float]?
    
    var inMorning: Bool!
    var day: SunDay!
    
    var firstLoad = true
    
    let NameHorizontalPadding: CGFloat = 20
    
    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    convenience init (startDegrees: Float, endDegrees: Float, name: String, colour: UIColor, day: SunDay, inMorning: Bool) {
        self.init(frame:CGRect.zero)
        
        self.startDegrees = startDegrees
        self.endDegrees = endDegrees
        self.name = name
        self.colour = colour
        self.day = day
        self.inMorning = inMorning
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func createArea(_ parentView: UIView) {
        self.parentView = parentView

        translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(self)

        // Area View

        let viewHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": self])
        topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)

        NSLayoutConstraint.activate(viewHorizontalConstraints + [topConstraint, heightConstraint])

        gradientLayer = CAGradientLayer()
        layer.addSublayer(gradientLayer)
        gradientLayer.frame = frame

        if let locations = locations {
            gradientLayer.locations = locations as [NSNumber]?
        } else {
            gradientLayer.locations = [
                0,
                0.2,
                0.8,
                1
            ]
        }

        if let colours = colours {
            gradientLayer.colors = colours
        } else {
            gradientLayer.colors = [
                colour.withAlphaComponent(0.1).cgColor,
                colour.cgColor,
                colour.cgColor,
                colour.withAlphaComponent(0.1).cgColor
            ]
        }

        // Hide view initially
        alpha = 0
    }
    
    func fadeOutView() {
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0
        }
    }
    
    func fadeInView() {
        if firstLoad {
            return
        }
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1
        }
    }
    
    func degreesToPercent(_ minMarker: SunTimeMarker, maxMarker: SunTimeMarker, findDegree: Float) -> Float {
        let minDegree = minMarker.sunTimeLine.suntime.type.degrees
        let maxDegree = maxMarker.sunTimeLine.suntime.type.degrees
        
        let minPercent = minMarker.percent
        let maxPercent = maxMarker.percent
        
        let degreeScale: Float = (maxDegree - minDegree) / (findDegree - minDegree)
        let scaledPercent: Float = ((maxPercent - minPercent) / degreeScale) + minPercent
        return scaledPercent
    }
    
    func updateAreaWithPercents(_ minPercent: Float, maxPercent: Float) {
        if "\(minPercent)" == "nan" || "\(maxPercent)" == "nan" {
            return
        }
        
        if minPercent < 0 || minPercent > 100 || maxPercent < 0 || maxPercent > 100 {
            return
        }
        
        let top = parentView.frame.height * CGFloat(minPercent)
        let bottom = parentView.frame.height * CGFloat(maxPercent)
        let height = bottom - top
        
        topConstraint.constant = top
        heightConstraint.constant = height
        
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: height)
        UIView.animate(withDuration: 0.5, animations: {
            self.parentView.layoutIfNeeded()
            }, completion: { finished in
            if self.firstLoad {
                self.firstLoad = false
                self.fadeInView()
            }
        })
    }
    
    func updateArea(_ sunTimeMarkers: [SunTimeMarker]) {
        // Only use relevant markers
        let filteredMarkers = sunTimeMarkers.filter { marker in
            return marker.sunTimeLine.suntime.day == self.day &&
                marker.sunTimeLine.suntime.type.morning == self.inMorning
        }

        // Sort markers by degrees
        let sortedMarkers = filteredMarkers.sorted { lhs, rhs in
            return lhs.sunTimeLine.suntime.type.degrees < rhs.sunTimeLine.suntime.type.degrees
        }

        var lowestMarker: SunTimeMarker?
        var highestMarker: SunTimeMarker?
        for marker in sortedMarkers {
            let sunDegree = marker.sunTimeLine.suntime.type.degrees
            if sunDegree <= startDegrees || (startDegrees < 0 && (lowestMarker == nil || sunDegree < (lowestMarker?.sunTimeLine.suntime.type.degrees)!)) {
                lowestMarker = marker
            }
            if highestMarker == nil && sunDegree >= endDegrees {
                highestMarker = marker
            }
        }

        if let lowestMarker = lowestMarker {
            if let highestMarker = highestMarker {
                var minMarker = lowestMarker
                var maxMarker = highestMarker

                if minMarker.percent > maxMarker.percent {
                    swap(&minMarker, &maxMarker)
                }

                let startPercent = degreesToPercent(minMarker, maxMarker: maxMarker, findDegree: startDegrees)
                let endPercent = degreesToPercent(minMarker, maxMarker: maxMarker, findDegree: endDegrees)

                updateAreaWithPercents(min(startPercent, endPercent), maxPercent: max(startPercent, endPercent))
            }
        }

        if lowestMarker == nil || highestMarker == nil {
            fadeOutView()
        }
    }
}
