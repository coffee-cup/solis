//
//  MomentumScroll.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-22.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class MomentumScroll: NSObject, UIDynamicItem {
    
    var bounds: CGRect
    var center: CGPoint = CGPoint.zero
    var transform: CGAffineTransform

    init(sunView: UIView) {
        bounds = sunView.bounds
        center = sunView.center
        transform = sunView.transform
    }
}
