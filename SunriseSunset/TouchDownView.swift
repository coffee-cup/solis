//
//  File.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-25.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

protocol TouchDownProtocol {
    func touchDown(touches: Set<UITouch>, withEvent event: UIEvent?)
}

class TouchDownView: UIView {
    var delegate: TouchDownProtocol?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        delegate?.touchDown(touches, withEvent: event)
    }
}