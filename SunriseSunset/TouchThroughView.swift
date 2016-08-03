//
//  TouchThroughView.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-02.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class TouchThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return false
    }
}