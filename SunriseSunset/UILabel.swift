//
//  UILabel.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func addSimpleShadow() {
        self.layer.shadowColor = UIColor.black().cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 1)
        self.layer.shadowOpacity = 0.5
    }
}
