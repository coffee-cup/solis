//
//  Defaults.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation

enum DefaultKey {
    case TimeFormat
    case FirstLight
    case LastLight
    case Sunrise
    case Sunset
    case NotificationPreTime
    case CurrentLocation
    case LocationName
    case CurrentLocationName
    case LocationDateSet
    case CurrentLocationLatitude
    case CurrentLocationLongitude
    case LocationLatitude
    case LocationLongitude
    case LocationHistoryNames
    case LocationHistoryPlaceIDs
    case LocationTimeZoneAbbreviation
    case LocationTimeZoneOffset
    
    var description: String {
        switch self {
        case .TimeFormat: return "TimeFormat"
        case .FirstLight: return "FirstLight"
        case .LastLight: return "LastLight"
        case .Sunrise: return "Sunrise"
        case .Sunset: return "Sunset"
        case .NotificationPreTime: return "NotificationPreTime"
        case .CurrentLocation: return "CurrentLocation"
        case .LocationName: return "LocationName"
        case .CurrentLocationName: return "CurrentLocationName"
        case .LocationDateSet: return "LocationDateSet"
        case .CurrentLocationLatitude: return "CurrentLocationLatitude"
        case .CurrentLocationLongitude: return "CurrentLocationLongitude"
        case .LocationLatitude: return "LocationLatitude"
        case .LocationLongitude: return "LocationLongitude"
        case .LocationHistoryNames: return "LocationHistoryNames"
        case .LocationHistoryPlaceIDs: return "LocationHistoryPlaceIDs"
        case .LocationTimeZoneAbbreviation: return "LocationTimeZoneAbbreviation"
        case .LocationTimeZoneOffset: return "LocationTimeZoneOffset"
        }
    }
}

class Defaults {
    static let defaults = NSUserDefaults.init(suiteName: "group.SunriseSunset")!
    
    static var delta: Bool {
        let timeformat = defaults.stringForKey(MessageType.TimeFormat.description)
        return timeformat == "delta"
    }
    
    static var timeFormat: String {
        return defaults.stringForKey(DefaultKey.TimeFormat.description)!
    }
    
    static var currentTimeZoneAbb: String? {
        return defaults.stringForKey(DefaultKey.LocationTimeZoneAbbreviation.description)
    }
}