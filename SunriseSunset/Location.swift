//
//  Location.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-20.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftLocation

class Location {
    
    static let defaults = Defaults.defaults
    
    static let CHECK_THRESHOLD = 60 * 10; // seconds
    
    class func startLocationWatching() {
        LocationManager.shared.observeLocations(.Block, frequency: .Significant, onSuccess: { location in
            print("\nSignificat Location")
            saveLocation(location.coordinate)
            }, onError: {error in
                print(error)
        })
    }
    
    class func checkLocation() {
        LocationManager.shared.observeLocations(.Block, frequency: .OneShot, onSuccess: { location in
            print("\nOne Shot Location")
            saveLocation(location.coordinate)
        }) { error in
            print(error)
        }
    }
    
    class func getLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.doubleForKey(DefaultKey.LocationLatitude.description)
        let longitude = defaults.doubleForKey(DefaultKey.LocationLongitude.description)
        
        if latitude == 0 || longitude == 0 {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Returns if we need to update the location
    class func needCheck() -> Bool {
        if defaults.doubleForKey(DefaultKey.LocationLatitude.description) == 0 ||
            defaults.doubleForKey(DefaultKey.LocationLongitude.description) == 0 {
            return true
        }
        
        guard let date = defaults.objectForKey(DefaultKey.LocationDateSet.description) else {
            return false
        }
        
        guard let differenceSeconds = date.timeIntervalSinceNow else {
            return false
        }
        
        return (Int(differenceSeconds)) > CHECK_THRESHOLD
    }
    
    class func notifyLocation() {
        Bus.sendMessage(.LocationUpdate, data: nil)
    }
    
    class func saveLocation(location: CLLocationCoordinate2D) {
        let now = NSDate()
        
        defaults.setDouble(location.latitude, forKey: DefaultKey.LocationLatitude.description)
        defaults.setDouble(location.longitude, forKey: DefaultKey.LocationLongitude.description)
        defaults.setObject(now, forKey: DefaultKey.LocationDateSet.description)
        
        notifyLocation()
    }
}