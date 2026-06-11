//
//  InfoMenuView.swift
//  SunriseSunset
//

import SwiftUI

// Full-bleed gradient page mirroring the timeline's day-to-night bands; each
// band pushes its explainer. Reads the palette globals, so it doubles as a
// live preview of the selected theme.
struct AboutView: View {
    @State private var visible = false

    private let sections: [(info: InfoData, label: String, sublabel: String?)] = [
        (.day, "Day", nil),
        (.civilTwilight, "Civil", "twilight"),
        (.nauticalTwilight, "Nautical", "twilight"),
        (.astronomicalTwilight, "Astronomical", "twilight"),
        (.night, "Night", nil),
    ]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    sectionLink(section, index: index)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { visible = true }
    }

    // Day and night are flat colours; the three twilight sections sit on one
    // gradient spanning the middle 3/5 of the screen.
    private var background: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Color(risesetColour)
                    .frame(height: geo.size.height / 5)
                LinearGradient(
                    colors: [Color(risesetColour), Color(astronomicalColour)],
                    startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 3 / 5)
                Color(astronomicalColour)
                    .frame(height: geo.size.height / 5)
            }
        }
    }

    private func sectionLink(_ section: (info: InfoData, label: String, sublabel: String?), index: Int) -> some View {
        NavigationLink(value: section.info) {
            VStack(spacing: 2) {
                Text(section.label)
                    .font(.title2.weight(.light))
                if let sublabel = section.sublabel {
                    Text(sublabel)
                        .font(.footnote)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -300)
        .animation(
            .easeInOut(duration: 1).delay(Double(index + 1) * 0.2),
            value: visible)
    }
}
