//
//  TimeFormatters.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-19.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation

enum TimeFormat {
    case hour24
    case hour12
    case delta
    
    var description: String {
        switch(self) {
        case .hour24: return "HH:mm"
        case .hour12: return "h:mm a"
        case .delta: return "delta"
        }
    }
}

class TimeFormatters {
    static func timeFormatter(format: String) -> NSDateFormatter {
        let timeFormatter = NSDateFormatter()
        timeFormatter.timeZone = NSTimeZone.localTimeZone()
        timeFormatter.dateFormat = format
        return timeFormatter
    }
    
    static var formatter12h: NSDateFormatter {
        return TimeFormatters.timeFormatter(TimeFormat.hour12.description)
    }
    
    static var formatter24h: NSDateFormatter {
        return TimeFormatters.timeFormatter(TimeFormat.hour24.description)
    }
    
    static var formatterDelta: NSDateFormatter {
        return TimeFormatters.timeFormatter(TimeFormat.delta.description)
    }
    
    static var currentFormatter: NSDateFormatter? {
        let timeFormat = Defaults.timeFormat
        if timeFormat == TimeFormat.hour12.description {
            return formatter12h
        } else if timeFormat == TimeFormat.hour24.description {
            return formatter24h
        }
        return nil
    }
    
    static func currentFormattedString(time: NSDate) -> String {
        var text = ""
        
        let timeOffset = time.dateByAddingTimeInterval(0) // may have to change
        let hours = timeOffset.getHoursToNow()
        let minutes = timeOffset.getMinutesToNow()
        let hourMinutes = abs(minutes - (hours * 60))
        let inPast = timeOffset.timeIntervalSinceNow < 0
        
        if Defaults.delta {
            text += inPast ? "- " : "+ "
            if hours != 0 {
                text += "\(hours)h"
            }
            if hours != 0 && hourMinutes != 0 {
                text += " "
            }
            if hourMinutes != 0 {
                text += "\(hourMinutes)m"
            }
            if hours == 0 && hourMinutes == 0 {
                text = "--"
            }
        } else {
            if let formatter = currentFormatter {
                text = formatter.stringFromDate(time)
                text = text.stringByReplacingOccurrencesOfString("AM", withString: "am")
                text = text.stringByReplacingOccurrencesOfString("PM", withString: "pm")
            }
        }
        return text

    }
}