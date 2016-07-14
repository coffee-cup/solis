//
//  UIButton.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-09.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func addSimpleShadow() {
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(2, 1)
        self.layer.shadowOpacity = 0.5
    }
    
    func addUnderline(state: UIControlState = UIControlState.Normal) {
        if let title = currentTitle {
            let titleString: NSMutableAttributedString = NSMutableAttributedString(string: title)
            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0, title.characters.count))
            setAttributedTitle(titleString, forState: state)
        }
    }
}