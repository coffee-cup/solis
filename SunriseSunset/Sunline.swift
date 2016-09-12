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
    
    var time: Date!
    
    var colliding = false
    let CollidingMinutesThreshhold = 12
    let LineHorizontalPadding: CGFloat = 100
    let NameHorizontalPadding: CGFloat = 20
    
    let CollideAnimationDuration: TimeInterval = 0.25

    override init (frame : CGRect) {
        super.init(frame : frame)
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func createLine(_ parentView: UIView, type: SunType) {
        self.parentView = parentView
        
        DispatchQueue.main.async {
        
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
            self.topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)
            let edgeConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": self])
            NSLayoutConstraint.activate(edgeConstraints + [self.topConstraint])
            
            // Line Constraints
            self.lineLeftConstraint = NSLayoutConstraint(item: self.line, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
            self.lineRightConstraint = NSLayoutConstraint(item: self.line, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -self.LineHorizontalPadding)
            let lineVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view]|", options: [], metrics: nil, views: ["view": self.line])
            let lineHeightContraint = NSLayoutConstraint(item: self.line, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 1)
            NSLayoutConstraint.activate([self.lineLeftConstraint, self.lineRightConstraint, lineHeightContraint] + lineVerticalConstraints)
            
            // Name Constraints
            self.nameLeftConstraint = NSLayoutConstraint(item: self.nameLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: self.NameHorizontalPadding)
            let nameVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view]-2-|", options: [], metrics: nil, views: ["view": self.nameLabel])
            NSLayoutConstraint.activate(nameVerticalConstraints + [self.nameLeftConstraint])
            
            // Time Contstraints
            let timeCenterConstraint = NSLayoutConstraint(item: self.timeLabel, attribute: .centerY, relatedBy: .equal, toItem: self.line, attribute: .centerY, multiplier: 1, constant: 0)
            let timeHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[view]-10-|", options: [], metrics: nil, views: ["view": self.timeLabel])
            NSLayoutConstraint.activate(timeHorizontalConstraints + [timeCenterConstraint])
            
            self.backgroundColor = UIColor.red()
            self.line.backgroundColor = type.lineColour
            
            self.nameLabel.text = type.description.lowercased()
            self.nameLabel.textColor = nameTextColour
            self.nameLabel.font = fontTwilight
            
            self.timeLabel.textColor = timeTextColour
            self.timeLabel.text = "12:12"
            self.timeLabel.font = fontDetail
            
            self.nameLabel.addSimpleShadow()
            self.timeLabel.addSimpleShadow()
            
            self.isHidden = true
            self.alpha = 0
        }
    }
    
    func getTimeText(_ offset: TimeInterval) -> String {
        let text = TimeFormatters.currentFormattedString(time, timeZone: TimeZones.currentTimeZone)
        return text
    }
    
    // Animates the items in the sunline to avoid collision with now line
    // Returns whether there will be a collision with now line
    func animateAvoidCollision(_ offset: TimeInterval) -> Bool {
        let offsetTime = Date().addingTimeInterval(offset)
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
            // Fixes sunline overlap on iphone5 screens and smaller
            let namePaddingFraction: CGFloat = parentView.frame.width < 375 ? 3 : 1
            lineLeftConstraint.constant = LineHorizontalPadding
            nameLeftConstraint.constant = LineHorizontalPadding + (NameHorizontalPadding / namePaddingFraction)
            UIView.animate(withDuration: CollideAnimationDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
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
            UIView.animate(withDuration: CollideAnimationDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.layoutIfNeeded()
                self.timeLabel.alpha = 1
                }, completion: nil)
        }
        colliding = false
    }
    
    // Returns whether there will be a collision with now line
    func updateTime(_ offset: TimeInterval = 0) -> Bool {
        if time == nil {
            return false
        }
        
        let timeText = getTimeText(offset)
        let isCollision = animateAvoidCollision(offset)
        DispatchQueue.main.async {
            if self.time != nil {
                self.timeLabel.text = timeText
            }
        }
        return isCollision
    }

    func updateLine(_ time: Date, percent: Float, happens: Bool) {
        DispatchQueue.main.async {
            self.time = time
            self.updateTime()
            
            self.topConstraint.constant = self.parentView.frame.height * CGFloat(percent)
            UIView.animate(withDuration: 0.5) {
                self.parentView.layoutIfNeeded()
            }
            
            if happens {
                self.isHidden = false
                UIView.animate(withDuration: 0.5, delay: 1, options: UIViewAnimationOptions(), animations: {
                    self.alpha = 1
                    }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.5, delay: 1, options: UIViewAnimationOptions(), animations: {
                    self.alpha = 0
                    }, completion: nil)
            }
        }
    }
}
