//
//  Styles.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-15.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Themes

// Selectable timeline palettes, persisted in the app-group defaults so the
// widget renders with the same theme. The launch screen gradient is a static
// asset baked with Classic colours and intentionally does not follow.
enum SunTheme: String, CaseIterable {
    case classic
    case ember
    case midnight
    case aurora
    case infrared

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .ember: return "Ember"
        case .midnight: return "Midnight"
        case .aurora: return "Aurora"
        case .infrared: return "Infrared"
        }
    }

    var palette: SunPalette {
        switch self {
        case .classic: return .classic
        case .ember: return .ember
        case .midnight: return .midnight
        case .aurora: return .aurora
        case .infrared: return .infrared
        }
    }

    static var current: SunTheme {
        let stored = Defaults.defaults.string(forKey: DefaultKey.theme.description) ?? ""
        return SunTheme(rawValue: stored) ?? .classic
    }
}

// Band colours run lightest (riseset) to darkest (astronomical) in every
// palette so the white timeline text stays legible on all bands.
struct SunPalette: Sendable {
    let riseset: UIColor
    let civil: UIColor
    let nautical: UIColor
    let astronomical: UIColor
    let lightLine: UIColor
    let darkLine: UIColor
    let goldenHour: UIColor
    let blueHour: UIColor

    static let classic = SunPalette(
        riseset: UIColor(hex: 0x46EAE7),
        civil: UIColor(hex: 0x4A9DCF),
        nautical: UIColor(hex: 0x4E50B8),
        astronomical: UIColor(hex: 0x52009F),
        lightLine: UIColor(hex: 0x00D3D0),
        darkLine: UIColor(hex: 0x6A00CD),
        goldenHour: UIColor(hex: 0xFFEC00).withAlphaComponent(0.2),
        blueHour: UIColor(hex: 0x03FFFB).withAlphaComponent(0.2))

    static let ember = SunPalette(
        riseset: UIColor(hex: 0xFFC069),
        civil: UIColor(hex: 0xE8765A),
        nautical: UIColor(hex: 0xA8456E),
        astronomical: UIColor(hex: 0x4A1242),
        lightLine: UIColor(hex: 0xFFD98C),
        darkLine: UIColor(hex: 0xC24B7E),
        goldenHour: UIColor(hex: 0xFFC400).withAlphaComponent(0.2),
        blueHour: UIColor(hex: 0x9FB6FF).withAlphaComponent(0.2))

    static let midnight = SunPalette(
        riseset: UIColor(hex: 0x8FD8FF),
        civil: UIColor(hex: 0x4E86C9),
        nautical: UIColor(hex: 0x3D5BA9),
        astronomical: UIColor(hex: 0x141C52),
        lightLine: UIColor(hex: 0x66E0FF),
        darkLine: UIColor(hex: 0x6E7BFF),
        goldenHour: UIColor(hex: 0xFFE9A3).withAlphaComponent(0.2),
        blueHour: UIColor(hex: 0x7FD0FF).withAlphaComponent(0.2))

    static let aurora = SunPalette(
        riseset: UIColor(hex: 0x8CF5CD),
        civil: UIColor(hex: 0x35BFA0),
        nautical: UIColor(hex: 0x1E7C86),
        astronomical: UIColor(hex: 0x10243E),
        lightLine: UIColor(hex: 0x7CFFD4),
        darkLine: UIColor(hex: 0x2EC4B6),
        goldenHour: UIColor(hex: 0xE8FF9C).withAlphaComponent(0.2),
        blueHour: UIColor(hex: 0x66FFE8).withAlphaComponent(0.2))

    static let infrared = SunPalette(
        riseset: UIColor(hex: 0xFF7459),
        civil: UIColor(hex: 0xD93A30),
        nautical: UIColor(hex: 0x8E1B26),
        astronomical: UIColor(hex: 0x26060B),
        lightLine: UIColor(hex: 0xFFB3A0),
        darkLine: UIColor(hex: 0xCC4A3E),
        goldenHour: UIColor(hex: 0xFFAA33).withAlphaComponent(0.2),
        blueHour: UIColor(hex: 0xFF7B9E).withAlphaComponent(0.2))
}

// MARK: - Theme-aware colours

// Read on view creation and gradient recompute, never per frame. A theme
// change re-renders through SunViewController.applyTheme().
var risesetColour: UIColor { SunTheme.current.palette.riseset }
var civilColour: UIColor { SunTheme.current.palette.civil }
var nauticalColour: UIColor { SunTheme.current.palette.nautical }
var astronomicalColour: UIColor { SunTheme.current.palette.astronomical }

var lightLineColour: UIColor { SunTheme.current.palette.lightLine }
var darkLineColour: UIColor { SunTheme.current.palette.darkLine }

var goldenHourColour: UIColor { SunTheme.current.palette.goldenHour }
var blueHourColour: UIColor { SunTheme.current.palette.blueHour }

// MARK: - Theme-invariant styles

let nowLineColour = UIColor(hex: 0xF44336)
let middleLineColour = UIColor.white.withAlphaComponent(0.5)

let nameTextColour = UIColor.white.withAlphaComponent(0.8)
let timeTextColour = UIColor.white.withAlphaComponent(0.8)

let fontLight = "Muli-Light"
let fontRegular = "Muli"

let fontTwilight = UIFont(name: fontRegular, size: 12)
let fontDetail = UIFont(name: fontRegular, size: 16)
