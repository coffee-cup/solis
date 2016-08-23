//
//  BellButton.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-22.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class BellButton: UIButton {
    var sunPlace: SunPlace?
    
    var useCurrentLocation: Bool {
        return sunPlace == nil
    }
}