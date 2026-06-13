//
//  RootView.swift
//  SunriseSunset
//

import SwiftUI

struct RootView: View {
    @Environment(LocationModel.self) private var location
    @Environment(\.scenePhase) private var scenePhase

    @State private var resetToken = 0
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TimelineView(resetToken: resetToken)
                .ignoresSafeArea()

            settingsButton
        }
        .statusBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                // Faded material: blurred glass that still lets the timeline
                // gradient read through.
                .presentationBackground {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.65)
                }
        }
        .onAppear {
            location.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                resetToken += 1
            }
        }
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("settings")
        .padding(.leading, 23)
        .padding(.bottom, 23)
    }
}

#Preview {
    RootView()
        .environment(LocationModel())
        .environment(SettingsModel())
}
