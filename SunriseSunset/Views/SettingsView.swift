//
//  SettingsView.swift
//  SunriseSunset
//

import SwiftUI

// Translucent row fill that lets the sheet's glass background read through.
private let glassRowFill = Color.primary.opacity(0.06)

// Pushed pages inside the settings stack. All navigation is value-based; the
// destinations are registered once on the stack root (mixing view-destination
// links with value pushes double-pushes on iOS 26).
enum SettingsRoute: Hashable {
    case location
    case themes
    case learn
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationModel.self) private var location
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(value: SettingsRoute.location) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.locationName ?? "Choose Location")
                                if location.isCurrentLocation {
                                    Text("Current Location")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "location.fill")
                        }
                    }
                    .accessibilityIdentifier("locationRow")
                }
                .listRowBackground(glassRowFill)

                Section("Appearance") {
                    NavigationLink(value: SettingsRoute.themes) {
                        HStack {
                            Label("Theme", systemImage: "paintpalette.fill")
                            Spacer()
                            ThemeSwatch(palette: currentTheme.palette)
                            Text(currentTheme.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker(selection: timeFormatBinding) {
                        Text("12-hour").tag(TimeFormat.hour12)
                        Text("24-hour").tag(TimeFormat.hour24)
                        Text("Relative (±)").tag(TimeFormat.delta)
                    } label: {
                        Label("Time Format", systemImage: "clock.fill")
                    }
                }
                .listRowBackground(glassRowFill)

                Section {
                    alertToggle(.sunrise, title: "Sunrise", icon: "sunrise.fill")
                    alertToggle(.sunset, title: "Sunset", icon: "sunset.fill")
                    alertToggle(.firstLight, title: "First Light", icon: "sun.haze.fill")
                    alertToggle(.lastLight, title: "Last Light", icon: "moon.haze.fill")
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notifications fire for the place marked with the bell in location search.")
                }
                .listRowBackground(glassRowFill)

                Section {
                    NavigationLink(value: SettingsRoute.learn) {
                        Label("Learn", systemImage: "book.fill")
                    }
                }
                .listRowBackground(glassRowFill)
            }
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .location: LocationSearchView(onSelect: { dismiss() })
                case .themes: ThemePickerView()
                case .learn: LearnView()
                }
            }
            .navigationDestination(for: InfoData.self) { info in
                InfoView(info: info)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var currentTheme: SunTheme {
        SunTheme(rawValue: settings.theme) ?? .classic
    }

    private var timeFormatBinding: Binding<TimeFormat> {
        Binding {
            switch settings.timeFormat {
            case TimeFormat.hour24.description: .hour24
            case TimeFormat.delta.description: .delta
            default: .hour12
            }
        } set: { format in
            settings.setTimeFormat(format)
        }
    }

    private func alertToggle(_ alert: SunAlert, title: String, icon: String) -> some View {
        Toggle(isOn: alertBinding(alert)) {
            Label(title, systemImage: icon)
        }
    }

    // Enabling prompts for notification permission; a denial leaves the model
    // off and the toggle snaps back.
    private func alertBinding(_ alert: SunAlert) -> Binding<Bool> {
        Binding {
            settings.isEnabled(alert)
        } set: { enabled in
            guard enabled != settings.isEnabled(alert) else { return }
            Task {
                await settings.toggleAlert(alert)
            }
        }
    }
}

struct ThemePickerView: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        List(SunTheme.allCases, id: \.self) { theme in
            Button {
                settings.setTheme(theme)
            } label: {
                HStack(spacing: 12) {
                    ThemeSwatch(palette: theme.palette)
                    Text(theme.displayName)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if settings.theme == theme.rawValue {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .accessibilityLabel(theme.displayName)
            .listRowBackground(glassRowFill)
        }
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Mini vertical gradient of the palette's day-to-night bands, mirroring the
// timeline's dusk progression.
struct ThemeSwatch: View {
    let palette: SunPalette

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(
                colors: [
                    Color(palette.riseset),
                    Color(palette.civil),
                    Color(palette.nautical),
                    Color(palette.astronomical),
                ],
                startPoint: .top, endPoint: .bottom))
            .frame(width: 48, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.quaternary, lineWidth: 1))
    }
}
