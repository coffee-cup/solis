//
//  TimelineView.swift
//  SunriseSunset
//

import SwiftUI

// Hosts the UIKit timeline. Reading the observable models inside
// updateUIViewController is what re-invokes it on every relevant mutation —
// the view controller diffs the tokens and reacts.
struct TimelineView: UIViewControllerRepresentable {
    @Environment(LocationModel.self) private var location
    @Environment(SettingsModel.self) private var settings

    // Bumped by RootView when the app foregrounds; recenters the timeline.
    let resetToken: Int

    func makeUIViewController(context: Context) -> SunViewController {
        SunViewController()
    }

    func updateUIViewController(_ controller: SunViewController, context: Context) {
        controller.apply(
            updateToken: location.updateToken,
            changeToken: location.changeToken,
            resetToken: resetToken,
            timeFormat: settings.timeFormat,
            themeID: settings.theme)
    }
}
