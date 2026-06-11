//
//  File.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-25.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

@MainActor
protocol TouchDownProtocol: AnyObject {
    func touchDown(_ touches: Set<UITouch>, withEvent event: UIEvent?)
}

class TouchDownView: UIView {
    weak var delegate: TouchDownProtocol?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.touchDown(touches, withEvent: event)
    }
}
