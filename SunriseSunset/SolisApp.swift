//
//  SolisApp.swift
//  SunriseSunset
//

import SwiftUI

@main
struct SolisApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var location = LocationModel()
    @State private var settings = SettingsModel()
    @State private var menu = MenuState()

    init() {
        Defaults.defaults.register(defaults: [
            DefaultKey.timeFormat.description: "h:mm a",
            DefaultKey.firstLight.description: false,
            DefaultKey.lastLight.description: false,
            DefaultKey.sunset.description: false,
            DefaultKey.sunrise.description: false,
            DefaultKey.notificationPreTime.description: 60 * 60 * 5, // minutes
            DefaultKey.currentLocation.description: true,
            DefaultKey.locationHistoryPlaces.description: [],
            DefaultKey.showSunAreas.description: true,
            DefaultKey.theme.description: SunTheme.classic.rawValue,
        ])

        BackgroundRefresh.register()

        Task {
            await NotificationScheduler.reschedule()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(location)
                .environment(settings)
                .environment(menu)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefresh.schedule()
            }
        }
    }
}
