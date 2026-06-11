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

        line = UIView()
        timeLabel = UILabel()
        nameLabel = UILabel()

        translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(self)
        addSubview(line)
        addSubview(timeLabel)
        addSubview(nameLabel)

        // View Contraints
        topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)
        let edgeConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": self])
        NSLayoutConstraint.activate(edgeConstraints + [topConstraint])

        // Line Constraints
        lineLeftConstraint = NSLayoutConstraint(item: line!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        lineRightConstraint = NSLayoutConstraint(item: line!, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -LineHorizontalPadding)
        let lineVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view]|", options: [], metrics: nil, views: ["view": line!])
        let lineHeightContraint = NSLayoutConstraint(item: line!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 1)
        NSLayoutConstraint.activate([lineLeftConstraint, lineRightConstraint, lineHeightContraint] + lineVerticalConstraints)

        // Name Constraints
        nameLeftConstraint = NSLayoutConstraint(item: nameLabel!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: NameHorizontalPadding)
        let nameVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[view]-2-|", options: [], metrics: nil, views: ["view": nameLabel!])
        NSLayoutConstraint.activate(nameVerticalConstraints + [nameLeftConstraint])

        // Time Contstraints
        let timeCenterConstraint = NSLayoutConstraint(item: timeLabel!, attribute: .centerY, relatedBy: .equal, toItem: line, attribute: .centerY, multiplier: 1, constant: 0)
        let timeHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[view]-10-|", options: [], metrics: nil, views: ["view": timeLabel!])
        NSLayoutConstraint.activate(timeHorizontalConstraints + [timeCenterConstraint])

        backgroundColor = UIColor.red
        line.backgroundColor = type.lineColour

        nameLabel.text = type.description.lowercased()
        nameLabel.textColor = nameTextColour
        nameLabel.font = fontTwilight

        timeLabel.textColor = timeTextColour
        timeLabel.text = "12:12"
        timeLabel.font = fontDetail

        nameLabel.addSimpleShadow()
        timeLabel.addSimpleShadow()

        isHidden = true
        alpha = 0
    }
    
    func getTimeText(_ offset: TimeInterval) -> String {
        let text = TimeFormatters.currentFormattedString(time, timeZone: SunLocation.currentTimeZone)
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
            UIView.animate(withDuration: CollideAnimationDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
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
            UIView.animate(withDuration: CollideAnimationDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
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
        if time != nil {
            timeLabel.text = timeText
        }
        return isCollision
    }

    func updateLine(_ time: Date, percent: Float, happens: Bool) {
        self.time = time
        let _ = updateTime()

        topConstraint.constant = parentView.frame.height * CGFloat(percent)
        UIView.animate(withDuration: 0.5) {
            self.parentView.layoutIfNeeded()
        }

        if happens {
            isHidden = false
            UIView.animate(withDuration: 0.5, delay: 1, options: UIView.AnimationOptions(), animations: {
                self.alpha = 1
                }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 1, options: UIView.AnimationOptions(), animations: {
                self.alpha = 0
                }, completion: nil)
        }
    }
}
