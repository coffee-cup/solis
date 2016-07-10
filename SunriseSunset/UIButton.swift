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
}