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
        self.layer.shadowColor = UIColor.black().cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 1)
        self.layer.shadowOpacity = 0.5
    }
    
    func addUnderline(_ colour: UIColor = UIColor.white(), state: UIControlState = UIControlState()) {
        if let title = currentTitle {
            let titleString: NSMutableAttributedString = NSMutableAttributedString(string: title)
            let fullRange = NSMakeRange(0, title.characters.count)
            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: fullRange)
            titleString.addAttribute(NSForegroundColorAttributeName, value: colour, range: fullRange)
            setAttributedTitle(titleString, for: state)
        }
    }
}
