//
//  InfoMenuView.swift
//  SunriseSunset
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var presentedInfo: InfoData?
    @State private var visible = false

    private let sections: [(info: InfoData, label: String, sublabel: String?)] = [
        (.day, "Day", nil),
        (.civilTwilight, "Civil", "twilight"),
        (.nauticalTwilight, "Nautical", "twilight"),
        (.astronomicalTwilight, "Astronomical", "twilight"),
        (.night, "Night", nil),
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            background

            VStack(spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    sectionButton(section, index: index)
                }
            }

            Button {
                dismiss()
            } label: {
                Image("back_light")
                    .padding(14)
            }
            .accessibilityLabel("back")
            .padding(.leading, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea()
        .statusBarHidden(false)
        .onAppear { visible = true }
        .fullScreenCover(item: $presentedInfo) { info in
            InfoView(info: info)
        }
        .gesture(edgeSwipeBack)
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

    private func sectionButton(_ section: (info: InfoData, label: String, sublabel: String?), index: Int) -> some View {
        Button {
            presentedInfo = section.info
        } label: {
            VStack(spacing: 2) {
                Text(section.label)
                    .font(.custom(fontLight, size: 28))
                if let sublabel = section.sublabel {
                    Text(sublabel)
                        .font(.custom(fontLight, size: 14))
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

    private var edgeSwipeBack: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.startLocation.x < 30 && value.translation.width > 80 {
                    dismiss()
                }
            }
    }
}

extension InfoData: Identifiable {
    var id: String { title }
}
