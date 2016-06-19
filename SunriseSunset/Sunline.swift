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
    
    var time: NSDate!

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
            
            self.topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1, constant: 0)
            let edgeConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": self])
            NSLayoutConstraint.activateConstraints(edgeConstraints + [self.topConstraint])
            
            let lineHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]-100-|", options: [], metrics: nil, views: ["view": self.line])
            let lineVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]|", options: [], metrics: nil, views: ["view": self.line])
            let lineHeightContraint = NSLayoutConstraint(item: self.line, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 1)
            NSLayoutConstraint.activateConstraints(lineHorizontalConstraints + lineVerticalConstraints + [lineHeightContraint])
            
            let nameVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]-2-|", options: [], metrics: nil, views: ["view": self.nameLabel])
            let nameHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[view]", options: [], metrics: nil, views: ["view": self.nameLabel])
            NSLayoutConstraint.activateConstraints(nameVerticalConstraints + nameHorizontalConstraints)
            
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
        var text = TimeFormatters.currentFormattedString(time)
        return text
    }
    
    func updateTime(offset: NSTimeInterval = 0) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.time != nil {
                self.timeLabel.text = self.getTimeText(offset)
            }
        }
    }

    func updateLine(time: NSDate, percent: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.time = time
            self.updateTime()
            
            self.topConstraint.constant = self.parentView.frame.height * CGFloat(percent)
            UIView.animateWithDuration(0.5) {
                self.parentView.layoutIfNeeded()
            }
            
            if self.hidden {
                self.hidden = false
                UIView.animateWithDuration(0.5, delay: 1, options: .CurveEaseInOut, animations: {
                    self.alpha = 1
                    }, completion: nil)
            }
        }
    }
}
