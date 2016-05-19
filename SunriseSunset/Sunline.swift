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
    let formatter = NSDateFormatter()

    override init (frame : CGRect) {
        super.init(frame : frame)
        formatter.dateFormat = "H:mm"
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func createLine(parentView: UIView, type: SunType) {
        self.parentView = parentView
        
        line = UIView()
        timeLabel = UILabel()
        nameLabel = UILabel()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        parentView.addSubview(self)
        self.addSubview(line)
        self.addSubview(timeLabel)
        self.addSubview(nameLabel)
        
        topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1, constant: 0)
        let edgeConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": self])
        NSLayoutConstraint.activateConstraints(edgeConstraints + [topConstraint])
        
        let lineHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]-100-|", options: [], metrics: nil, views: ["view": line])
        let lineVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]|", options: [], metrics: nil, views: ["view": line])
        let lineHeightContraint = NSLayoutConstraint(item: line, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 1)
        NSLayoutConstraint.activateConstraints(lineHorizontalConstraints + lineVerticalConstraints + [lineHeightContraint])
        
        let nameVerticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view]-2-|", options: [], metrics: nil, views: ["view": nameLabel])
        let nameHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[view]", options: [], metrics: nil, views: ["view": nameLabel])
        NSLayoutConstraint.activateConstraints(nameVerticalConstraints + nameHorizontalConstraints)
        
        let timeCenterConstraint = NSLayoutConstraint(item: timeLabel, attribute: .CenterY, relatedBy: .Equal, toItem: line, attribute: .CenterY, multiplier: 1, constant: 0)
        let timeHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-20-|", options: [], metrics: nil, views: ["view": timeLabel])
        NSLayoutConstraint.activateConstraints(timeHorizontalConstraints + [timeCenterConstraint])
        
        self.backgroundColor = UIColor.redColor()
        line.backgroundColor = type.lineColour
        
        nameLabel.text = type.description.lowercaseString
        nameLabel.textColor = nameTextColour
        nameLabel.font = nameLabel.font.fontWithSize(12)
        
        timeLabel.textColor = timeTextColour
        timeLabel.text = "12:12"
        timeLabel.font = timeLabel.font.fontWithSize(16)
        
        self.hidden = true
        self.alpha = 0
    }

    func updateLine(time: NSDate, percent: Float) {
        let text = formatter.stringFromDate(time)
        timeLabel.text = text
        
        topConstraint.constant = parentView.frame.height * CGFloat(percent)
        UIView.animateWithDuration(0.1) {
            self.parentView.layoutIfNeeded()
        }
        
        if self.hidden {
            self.hidden = false
            UIView.animateWithDuration(1, delay: 1, options: .CurveEaseInOut, animations: {
                self.alpha = 1
                }, completion: nil)
        }
    }
    
}
