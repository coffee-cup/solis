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
    
    class func getPlaceID() -> String? {
        return defaults.stringForKey(DefaultKey.LocationPlaceID.description)
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
    
    class func setLocation(current: Bool, location: CLLocationCoordinate2D, name: String, sunplace: SunPlace? = nil) {
        defaults.setObject(name, forKey: DefaultKey.LocationName.description)
        defaults.setDouble(location.latitude, forKey: DefaultKey.LocationLatitude.description)
        defaults.setDouble(location.longitude, forKey: DefaultKey.LocationLongitude.description)
        defaults.setBool(current, forKey: DefaultKey.CurrentLocation.description)
        
        if !current {
            defaults.setObject(sunplace?.placeID, forKey: DefaultKey.LocationPlaceID.description)
            Bus.sendMessage(.FetchTimeZone, data: nil)
        }
    
        notifyLocation()
    }
    
    class func selectLocation(current: Bool, location: CLLocationCoordinate2D?, name: String?, sunplace: SunPlace?) {
        if current {
            if let currentLocation = getCurrentLocation() {
                if let locationName = getCurrentLocationName() {
                    setLocation(true, location: currentLocation, name: locationName)
                }
            }
            checkLocation()
        } else {
            if let sunplace = sunplace {
                setLocation(false, location: location!, name: name!, sunplace: sunplace)
                addLocationToHistory(sunplace)
                if let timeZoneOffset = sunplace.timeZoneOffset {
                    print("setting timezone offset from saved \(timeZoneOffset)")
                    Defaults.defaults.setInteger(timeZoneOffset, forKey: DefaultKey.LocationTimeZoneOffset.description)
                }
            }
        }
        Bus.sendMessage(.LocationUpdate, data: nil)
    }
    
    class func updateLocationHistoryWithTimeZone(location: CLLocationCoordinate2D, placeID: String, timeZoneOffset: Int) {
        if let locationHistory = getLocationHistory() {
            let index = locationHistory.indexOf { place in
                return place.placeID == placeID
            }
            if let index = index {
                if index >= 0 && index < locationHistory.count {
                    let sunplace = locationHistory[index]
                    sunplace.timeZoneOffset = timeZoneOffset
                    print("saving timezoneoffset to history \(timeZoneOffset)")
                    addLocationToHistory(sunplace)
                }
            }
        }
    }
    
    class func getLocationHistory() -> [SunPlace]? {
        if let locationHistoryPlaces = defaults.objectForKey(DefaultKey.LocationHistoryPlaces.description) as? [String] {
            var places: [SunPlace] = []
            for placeString in locationHistoryPlaces {
                if let sunplace = SunPlace.sunPlaceFromString(placeString) {
                    places.append(sunplace)
                }
            }
            return places
        }
        return nil
    }
    
    class func saveLocationHistory(places: [SunPlace]) {
        let placeStrings: [String] = places.map { place in
            if let placeString = place.toString {
                return placeString
            }
            return ""
        }
        defaults.setObject(placeStrings, forKey: DefaultKey.LocationHistoryPlaces.description)
    }
    
    class func addLocationToHistory(sunplace: SunPlace) {
        if var locationHistory: [SunPlace] = getLocationHistory() {
            if let index = locationHistory.indexOf(sunplace) {
                locationHistory.removeAtIndex(index)
            }
            
            locationHistory.insert(sunplace, atIndex: 0)
            
            if locationHistory.count > 5 {
                locationHistory = Array(locationHistory[0...4])
            }
            
            saveLocationHistory(locationHistory)
        }
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
    }
}