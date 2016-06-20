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
    
    class func getCurrentLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.doubleForKey(DefaultKey.CurrentLocationLatitude.description)
        let longitude = defaults.doubleForKey(DefaultKey.CurrentLocationLongitude.description)
        
        if latitude == 0 || longitude == 0 {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    class func getLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.doubleForKey(DefaultKey.LocationLatitude.description)
        let longitude = defaults.doubleForKey(DefaultKey.LocationLongitude.description)
        
        if latitude == 0 || longitude == 0 {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    class func getLocationName() -> String? {
        return defaults.stringForKey(DefaultKey.LocationName.description)
    }
    
    class func getCurrentLocationName() -> String? {
        return defaults.stringForKey(DefaultKey.CurrentLocationName.description)
    }
    
    class func isCurrentLocation() -> Bool {
        return defaults.boolForKey(DefaultKey.CurrentLocation.description)
    }
    
    class func lookupLocation(coordinate: CLLocationCoordinate2D, completion: (placemark: CLPlacemark?) -> ()) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let err = error{
                print("Error Reverse Geocoding Location: \(err.localizedDescription)")
                completion(placemark: nil)
                return
            }
            completion(placemark: placemarks![0])
        })
    }
    
    class func setLocation(current: Bool, location: CLLocationCoordinate2D, name: String) {
        defaults.setObject(name, forKey: DefaultKey.LocationName.description)
        defaults.setDouble(location.latitude, forKey: DefaultKey.LocationLatitude.description)
        defaults.setDouble(location.longitude, forKey: DefaultKey.LocationLongitude.description)
        defaults.setBool(current, forKey: DefaultKey.CurrentLocation.description)
        notifyLocation()
    }
    
    class func selectLocation(current: Bool, location: CLLocationCoordinate2D?, name: String?) {
        if current {
            if let currentLocation = getCurrentLocation() {
                if let locationName = getCurrentLocationName() {
                    setLocation(true, location: currentLocation, name: locationName)
                }
            }
            checkLocation()
        } else {
            setLocation(false, location: location!, name: name!)
        }
        Bus.sendMessage(.LocationUpdate, data: nil)
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
        
        lookupLocation(location) { placemark in
            var name = ""
            if let placemark = placemark {
                if let city = placemark.locality {
                    name = city
                }
            }
            
            defaults.setDouble(location.latitude, forKey: DefaultKey.CurrentLocationLatitude.description)
            defaults.setDouble(location.longitude, forKey: DefaultKey.CurrentLocationLongitude.description)
            defaults.setObject(name, forKey: DefaultKey.CurrentLocationName.description)
            if isCurrentLocation() {
                setLocation(true, location: location, name: name)
                defaults.setObject(now, forKey: DefaultKey.LocationDateSet.description)
            }
        }
    }
}