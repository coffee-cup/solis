//
//  MenuState.swift
//  SunriseSunset
//

import Observation
import SwiftUI

// Slide-out menu position. 0 = closed, 1 = fully out; intermediate values
// track an in-flight drag so the dim overlay can follow the finger.
@MainActor
@Observable
final class MenuState {

    private(set) var fraction: CGFloat = 0

    var isOut: Bool { fraction > 0 }

    func open() {
        withAnimation(.easeOut(duration: 0.25)) {
            fraction = 1
        }
    }

    func close() {
        withAnimation(.easeOut(duration: 0.25)) {
            fraction = 0
        }
    }

    func setDragFraction(_ value: CGFloat) {
        fraction = min(max(value, 0), 1)
    }

    func settle() {
        if fraction > 0.5 {
            open()
        } else {
            close()
        }
    }
}
