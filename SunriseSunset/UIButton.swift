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
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 1)
        self.layer.shadowOpacity = 0.5
    }
    
    func addUnderline(_ colour: UIColor = UIColor.white, state: UIControl.State = UIControl.State()) {
        if let title = currentTitle {
            let titleString: NSMutableAttributedString = NSMutableAttributedString(string: title)
            let fullRange = NSMakeRange(0, title.characters.count)
            titleString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: fullRange)
            titleString.addAttribute(NSAttributedString.Key.foregroundColor, value: colour, range: fullRange)
            setAttributedTitle(titleString, for: state)
        }
    }
}
