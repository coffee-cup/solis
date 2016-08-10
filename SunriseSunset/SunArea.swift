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
    var bottomConstraint: NSLayoutConstraint!
    
    var nameLeftConstraint: NSLayoutConstraint!
    
    var startDegrees: Float!
    var endDegrees: Float!
    var name: String!
    var colour: UIColor!
    
    var inMorning: Bool!
    var day: SunDay!
    
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
    
    func createArea(parentView: UIView) {
        self.parentView = parentView
        
        dispatch_async(dispatch_get_main_queue()) {
            self.nameLabel = UILabel()
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            parentView.addSubview(self)
            
//            self.addSubview(self.nameLabel)
            
            // Area View
            
            let viewHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": self])
//            let viewVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: ["view": self])
            self.topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1, constant: 0)
            self.bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1, constant: 100)
            
//            NSLayoutConstraint.activateConstraints(viewHorizontalConstraints + viewVerticalConstraints)
            NSLayoutConstraint.activateConstraints(viewHorizontalConstraints + [self.topConstraint, self.bottomConstraint])
            
            self.backgroundColor = self.colour
            
            // Name Label
            
//            let nameVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]-2-|", options: [], metrics: nil, views: ["view": self.nameLabel])
//            self.nameLeftConstraint = NSLayoutConstraint(item: self.nameLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: self.NameHorizontalPadding)
//            
//            NSLayoutConstraint.activateConstraints(nameVerticalConstraints + [self.nameLeftConstraint])
            
//            self.nameLabel.textColor = nameTextColour
//            self.nameLabel.font = fontTwilight
//            self.nameLabel.text = self.name
        }
    }
    
    func fadeOutView() {
        UIView.animateWithDuration(0.5) {
            self.alpha = 0
        }
    }
    
    func fadeInView() {
        UIView.animateWithDuration(0.5) {
            self.alpha = 1
        }
    }
    
    func degreesToPercent(minMarker: SunTimeMarker, maxMarker: SunTimeMarker, findDegree: Float) -> Float {
        let minDegree = minMarker.sunTimeLine.suntime.type.degrees
        let maxDegree = maxMarker.sunTimeLine.suntime.type.degrees
        
        let minPercent = minMarker.percent
        let maxPercent = maxMarker.percent
        
        let degreeScale: Float = (maxDegree - minDegree) / (findDegree - minDegree)
        let scaledPercent: Float = ((maxPercent - minPercent) / degreeScale) + minPercent
        return scaledPercent
    }
    
    func updateAreaWithPercents(minPercent: Float, maxPercent: Float) {
        topConstraint.constant = self.parentView.frame.height * CGFloat(minPercent)
        bottomConstraint.constant = self.parentView.frame.height * CGFloat(maxPercent)
        UIView.animateWithDuration(0.5) {
            self.parentView.layoutIfNeeded()
        }
    }
    
    func updateArea(sunTimeMarkers: [SunTimeMarker]) {
        dispatch_async(dispatch_get_main_queue()) {
            
            // Only use relevant markers
            let filteredMarkers = sunTimeMarkers.filter { marker in
                return marker.sunTimeLine.suntime.day == self.day &&
                    marker.sunTimeLine.suntime.type.morning == self.inMorning
            }
            
            // Sort markers by degrees
            let sortedMarkers = filteredMarkers.sort { lhs, rhs in
                return lhs.sunTimeLine.suntime.type.degrees < rhs.sunTimeLine.suntime.type.degrees
            }
            
            var lowestMarker: SunTimeMarker?
            var highestMarker: SunTimeMarker?
            for marker in sortedMarkers {
                let sunDegree = marker.sunTimeLine.suntime.type.degrees
                if sunDegree <= self.startDegrees || (self.startDegrees < 0 && (lowestMarker == nil || sunDegree < lowestMarker?.sunTimeLine.suntime.type.degrees)) {
                    lowestMarker = marker
                }
                if highestMarker == nil && sunDegree >= self.endDegrees {
                    highestMarker = marker
                }
            }
            
            if let lowestMarker = lowestMarker {
                if let highestMarker = highestMarker {
                    print("area range \(self.startDegrees) - \(self.endDegrees)")
                    print("\(lowestMarker.sunTimeLine.suntime.type.description):  \(lowestMarker.sunTimeLine.suntime.type.degrees)")
                    print("\(highestMarker.sunTimeLine.suntime.type.description): \(highestMarker.sunTimeLine.suntime.type.degrees)")
                    
                    var minMarker = lowestMarker
                    var maxMarker = highestMarker
                    
                    if minMarker.percent > maxMarker.percent {
                        swap(&minMarker, &maxMarker)
                    }
                    
                    let startPercent = self.degreesToPercent(minMarker, maxMarker: maxMarker, findDegree: self.startDegrees)
                    let endPercent = self.degreesToPercent(minMarker, maxMarker: maxMarker, findDegree: self.endDegrees)
                    
                    print("start deg: \(self.startDegrees) - per: \(startPercent)")
                    print("end deg: \(self.endDegrees) - per: \(endPercent)")
                    
                    self.updateAreaWithPercents(min(startPercent, endPercent), maxPercent: max(startPercent, endPercent))
                }
            }
            
            if lowestMarker == nil || highestMarker == nil {
                self.fadeOutView()
            }
        }
    }
}
