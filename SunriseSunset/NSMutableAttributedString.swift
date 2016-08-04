//
//  NSAttributedString.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-03.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    enum AtributeSearchType {
        case First, All, Last
    }
    
    func attributeRangeFor(searchString: String, attributeName: String, attributeValue: AnyObject, atributeSearchType: AtributeSearchType) {
        let inputLength = self.string.characters.count
        let searchLength = searchString.characters.count
        var range = NSRange(location: 0, length: self.length)
        var rangeCollection = [NSRange]()
        
        while (range.location != NSNotFound) {
            range = (self.string as NSString).rangeOfString(searchString, options: [], range: range)
            if (range.location != NSNotFound) {
                switch atributeSearchType {
                case .First:
                    self.addAttribute(attributeName, value: attributeValue, range: NSRange(location: range.location, length: searchLength))
                    return
                case .All:
                    self.addAttribute(attributeName, value: attributeValue, range: NSRange(location: range.location, length: searchLength))
                    break
                case .Last:
                    rangeCollection.append(range)
                    break
                }
                
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
            }
        }
        
        switch atributeSearchType {
        case .Last:
            let indexOfLast = rangeCollection.count - 1
            self.addAttribute(attributeName, value: attributeValue, range: rangeCollection[indexOfLast])
            break
        default:
            break
        }
    }
}