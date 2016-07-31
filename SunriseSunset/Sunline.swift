//
//  SunLine.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class Sunline: UIView {
    
    var line: UIView!
    var timeLabel: UILabel!
    var nameLabel: UILabel!
    
    var parentView: UIView!
    
    var topConstraint: NSLayoutConstraint!
    var lineLeftConstraint: NSLayoutConstraint!
    var lineRightConstraint: NSLayoutConstraint!
    var nameLeftConstraint: NSLayoutConstraint!
    
    var time: NSDate!
    
    var colliding = false
    let CollidingMinutesThreshhold = 12
    let LineHorizontalPadding: CGFloat = 100
    let NameHorizontalPadding: CGFloat = 20
    
    let CollideAnimationDuration: NSTimeInterval = 0.25

    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func createLine(parentView: UIView, type: SunType) {
        self.parentView = parentView
        
        dispatch_async(dispatch_get_main_queue()) {
        
            self.line = UIView()
            self.timeLabel = UILabel()
            self.nameLabel = UILabel()
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.line.translatesAutoresizingMaskIntoConstraints = false
            self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
            self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            parentView.addSubview(self)
            self.addSubview(self.line)
            self.addSubview(self.timeLabel)
            self.addSubview(self.nameLabel)
            
            // View Contraints
            self.topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1, constant: 0)
            let edgeConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": self])
            NSLayoutConstraint.activateConstraints(edgeConstraints + [self.topConstraint])
            
            // Line Constraints
            self.lineLeftConstraint = NSLayoutConstraint(item: self.line, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
            self.lineRightConstraint = NSLayoutConstraint(item: self.line, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -self.LineHorizontalPadding)
            let lineVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]|", options: [], metrics: nil, views: ["view": self.line])
            let lineHeightContraint = NSLayoutConstraint(item: self.line, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 1)
            NSLayoutConstraint.activateConstraints([self.lineLeftConstraint, self.lineRightConstraint, lineHeightContraint] + lineVerticalConstraints)
            
            // Name Constraints
            self.nameLeftConstraint = NSLayoutConstraint(item: self.nameLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: self.NameHorizontalPadding)
            let nameVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]-2-|", options: [], metrics: nil, views: ["view": self.nameLabel])
            NSLayoutConstraint.activateConstraints(nameVerticalConstraints + [self.nameLeftConstraint])
            
            // Time Contstraints
            let timeCenterConstraint = NSLayoutConstraint(item: self.timeLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.line, attribute: .CenterY, multiplier: 1, constant: 0)
            let timeHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-10-|", options: [], metrics: nil, views: ["view": self.timeLabel])
            NSLayoutConstraint.activateConstraints(timeHorizontalConstraints + [timeCenterConstraint])
            
            self.backgroundColor = UIColor.redColor()
            self.line.backgroundColor = type.lineColour
            
            self.nameLabel.text = type.description.lowercaseString
            self.nameLabel.textColor = nameTextColour
            self.nameLabel.font = fontTwilight
            
            self.timeLabel.textColor = timeTextColour
            self.timeLabel.text = "12:12"
            self.timeLabel.font = fontDetail
            
            self.nameLabel.addSimpleShadow()
            self.timeLabel.addSimpleShadow()
            
            self.hidden = true
            self.alpha = 0
        }
    }
    
    func getTimeText(offset: NSTimeInterval) -> String {
        let text = TimeFormatters.currentFormattedString(time, timeZone: TimeZones.currentTimeZone)
        return text
    }
    
    // Animates the items in the sunline to avoid collision with now line
    // Returns whether there will be a collision with now line
    func animateAvoidCollision(offset: NSTimeInterval) -> Bool {
        let offsetTime = NSDate().dateByAddingTimeInterval(offset)
        let difference = abs(offsetTime.getDifferenceInMinutes(time))
        
        if difference < CollidingMinutesThreshhold {
            animateForCollision()
            return true
        } else {
            animateToNormal()
        }
        return false
    }
    
    func animateForCollision() {
        if !colliding {
            lineLeftConstraint.constant = LineHorizontalPadding
            nameLeftConstraint.constant = LineHorizontalPadding + NameHorizontalPadding
            UIView.animateWithDuration(CollideAnimationDuration, delay: 0, options: .CurveEaseInOut, animations: {
                self.layoutIfNeeded()
                self.timeLabel.alpha = 0
                }, completion: nil)
        }
        colliding = true
    }
    
    func animateToNormal() {
        if colliding {
            lineLeftConstraint.constant = 0
            nameLeftConstraint.constant = NameHorizontalPadding
            UIView.animateWithDuration(CollideAnimationDuration, delay: 0, options: .CurveEaseInOut, animations: {
                self.layoutIfNeeded()
                self.timeLabel.alpha = 1
                }, completion: nil)
        }
        colliding = false
    }
    
    // Returns whether there will be a collision with now line
    func updateTime(offset: NSTimeInterval = 0) -> Bool {
        if time == nil {
            return false
        }
        
        let timeText = getTimeText(offset)
        let isCollision = animateAvoidCollision(offset)
        dispatch_async(dispatch_get_main_queue()) {
            if self.time != nil {
                self.timeLabel.text = timeText
            }
        }
        return isCollision
    }

    func updateLine(time: NSDate, percent: Float, happens: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.time = time
            self.updateTime()
            
            self.topConstraint.constant = self.parentView.frame.height * CGFloat(percent)
            UIView.animateWithDuration(0.5) {
                self.parentView.layoutIfNeeded()
            }
            
            if happens {
                self.hidden = false
                UIView.animateWithDuration(0.5, delay: 1, options: .CurveEaseInOut, animations: {
                    self.alpha = 1
                    }, completion: nil)
            } else {
                UIView.animateWithDuration(0.5, delay: 1, options: .CurveEaseInOut, animations: {
                    self.alpha = 0
                    }, completion: nil)
            }
        }
    }
}
