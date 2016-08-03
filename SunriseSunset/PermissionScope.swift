//
//  PermissionScope.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-02.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
import PermissionScope

extension PermissionScope {
    func style() {
        buttonFont = UIFont(name: fontRegular, size: buttonFont.pointSize)!
        labelFont = UIFont(name: fontRegular, size: labelFont.pointSize)!
        closeButtonTextColor = nauticalColour
        authorizedButtonColor = nauticalColour
        unauthorizedButtonColor = nowLineColour
        permissionButtonTextColor = nauticalColour
        permissionButtonBorderColor = nauticalColour
        
        bodyLabel.text = "We need something\r\nbefore you can start"
    }
}