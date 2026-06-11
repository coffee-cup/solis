//
//  SettingsView.swift
//  SunriseSunset
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationModel.self) private var location
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        LocationSearchView()
                    } label: {
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

                Section("Appearance") {
                    NavigationLink {
                        ThemePickerView()
                    } label: {
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

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Solis", systemImage: "info.circle.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundStyle(.primary)
                    Spacer()
                    if settings.theme == theme.rawValue {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .accessibilityLabel(theme.displayName)
        }
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
