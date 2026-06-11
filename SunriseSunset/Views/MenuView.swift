//
//  MenuView.swift
//  SunriseSunset
//

import SwiftUI

struct MenuView: View {
    @Environment(LocationModel.self) private var location
    @Environment(SettingsModel.self) private var settings

    @State private var showLocationSearch = false
    @State private var showInfoMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, 60)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("time format")
                timeFormatButtons
                    .padding(.top, 10)

                sectionLabel("notifications")
                    .padding(.top, 20)
                alertButtons
                    .padding(.top, 10)

                sectionLabel("location")
                    .padding(.top, 30)
                locationButton

                aboutButton
                    .padding(.top, 10)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(menuBackgroundColour))
        .fullScreenCover(isPresented: $showLocationSearch) {
            LocationSearchView()
                .statusBarHidden(false)
        }
        .fullScreenCover(isPresented: $showInfoMenu) {
            InfoMenuView()
        }
    }

    private var header: some View {
        HStack {
            Text("menu")
                .font(.custom(fontLight, size: 20))
                .foregroundStyle(.white)
            Spacer()
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 13)
                .padding(.trailing, 25)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom(fontLight, size: 20))
            .foregroundStyle(.white)
    }

    private var timeFormatButtons: some View {
        HStack {
            formatButton("24 h", format: .hour24)
            Spacer()
            formatButton("12 h", format: .hour12)
            Spacer()
            formatButton("±", format: .delta)
        }
        .padding(.trailing, 20)
    }

    private func formatButton(_ title: String, format: TimeFormat) -> some View {
        let selected = settings.timeFormat == format.description
        return Button(title) {
            settings.setTimeFormat(format)
        }
        .font(.custom(fontRegular, size: 16))
        .foregroundStyle(Color(selected ? buttonEnabled : buttonDisabled))
        .frame(width: 44, height: 44)
    }

    private var alertButtons: some View {
        HStack(alignment: .top, spacing: 60) {
            VStack(alignment: .leading, spacing: 20) {
                alertButton(.sunrise, title: "sunrise", iconOff: "rise_off", iconOn: "rise_on")
                alertButton(.sunset, title: "sunset", iconOff: "set_off", iconOn: "set_on")
            }
            VStack(alignment: .leading, spacing: 20) {
                alertButton(.firstLight, title: "first light", iconOff: "first_off", iconOn: "first_on")
                alertButton(.lastLight, title: "last light", iconOff: "last_off", iconOn: "last_on")
            }
        }
    }

    private func alertButton(_ alert: SunAlert, title: String, iconOff: String, iconOn: String) -> some View {
        let enabled = settings.isEnabled(alert)
        return Button {
            Task {
                await settings.toggleAlert(alert)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(enabled ? iconOn : iconOff)
                Text(title)
                    .font(.custom(fontRegular, size: 16))
                    .foregroundStyle(Color(enabled ? buttonEnabled : buttonDisabled))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var locationButton: some View {
        Button {
            showLocationSearch = true
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.locationName ?? "Choose Location")
                    .font(.custom(fontRegular, size: 16))
                    .foregroundStyle(Color(buttonEnabled))
                if location.isCurrentLocation {
                    Text("current location")
                        .font(.custom(fontLight, size: 10))
                        .foregroundStyle(Color(red: 0.275, green: 1, blue: 0.843))
                }
            }
            .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var aboutButton: some View {
        Button {
            showInfoMenu = true
        } label: {
            HStack(spacing: 10) {
                Image("info")
                Text("about")
                    .font(.custom(fontLight, size: 20))
                    .foregroundStyle(.white)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("about")
    }
}
