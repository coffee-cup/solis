//
//  InfoView.swift
//  SunriseSunset
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    let info: InfoData

    private static let highlightWords = [
        "day", "civil", "nautical", "astronomical", "night",
        "twilight", "dusk", "dawn",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text(info.title)
                .font(.custom(fontLight, size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let image = info.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                    }

                    Text(info.photoDescription)
                        .font(.custom(fontLight, size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Text(highlightedText)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
            }

            bottomBar
        }
        .background(Color(.systemBackground))
        .statusBarHidden(false)
        .gesture(edgeSwipeBack)
    }

    private var bottomBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image("back_light")
                    .padding(14)
            }
            .accessibilityLabel("back")

            Spacer()

            if let url = URL(string: info.learnMoreURL) {
                Link(destination: url) {
                    Text("Learn More")
                        .font(.custom(fontRegular, size: 16))
                        .underline()
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 20)
            }
        }
        .padding(.leading, 16)
        .padding(.vertical, 8)
        .background(Color(nauticalColour))
    }

    // Twilight vocabulary is tinted, matching the old attributed-string pass.
    // Attributes are set via explicit attribute types: the dynamic-member
    // keypath spelling trips a Sendable error in Swift 6.
    private var highlightedText: AttributedString {
        var attributed = AttributedString(info.text)
        attributed[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = .custom(fontRegular, size: 18)

        for word in Self.highlightWords {
            for variant in [word, word.capitalized] {
                var searchRange = attributed.startIndex..<attributed.endIndex
                while let found = attributed[searchRange].range(of: variant) {
                    attributed[found][AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = Color(civilColour)
                    if found.upperBound < attributed.endIndex {
                        searchRange = found.upperBound..<attributed.endIndex
                    } else {
                        break
                    }
                }
            }
        }
        return attributed
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
