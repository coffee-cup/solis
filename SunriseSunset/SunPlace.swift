//
//  SunPlace.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-25.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class SunPlace: Equatable {
    
    var location: CLLocationCoordinate2D?
    var placeID: String
    var timeZoneOffset: Int?
    
    var primary: String
    var secondary: String
    
    var isNotification: Bool = false
    
    class func sunPlaceFromString(string: String) -> SunPlace? {
        let split = string.characters.split{$0 == "|"}.map(String.init)
        
        if split.count < 5 {
            return nil
        }
        
        let primary = split[0]
        let secondary = split[1]
        
        let latitude = Double(split[2])!
        let longitude = Double(split[3])!
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let placeID = split[4]
        
        let timeZoneOffset = split.count >= 6 ? Int(split[5]) : nil
        
        let isNotification = split.count >= 7 ? split[6] == "true" : false
        
        return SunPlace(primary: primary, secondary: secondary, location: location, placeID: placeID, timeZoneOffset: timeZoneOffset, isNotification: isNotification)
    }
    
    init(primary: String, secondary: String, placeID: String) {
        self.primary = primary
        self.secondary = secondary
        self.placeID = placeID
    }
    
    init(primary: String, secondary: String, location: CLLocationCoordinate2D, placeID: String, timeZoneOffset: Int?, isNotification: Bool) {
        self.primary = primary
        self.secondary = secondary
        self.location = location
        self.placeID = placeID
        self.timeZoneOffset = timeZoneOffset
        self.isNotification = isNotification
    }
    
    var toString: String? {
        guard let location = location else {
            return nil
        }
        
        let tzOffset = timeZoneOffset == nil ? "" : "\(timeZoneOffset!)"
        
        return "\(primary)|\(secondary)|\(location.latitude)|\(location.longitude)|\(placeID)|\(tzOffset)|\(isNotification)"
    }
}

func ==(lhs: SunPlace, rhs: SunPlace) -> Bool {
    return lhs.placeID == rhs.placeID
}