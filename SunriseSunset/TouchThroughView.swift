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
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
