//
//  InfoView.swift
//  SunriseSunset
//

import SwiftUI

struct InfoView: View {
    let info: InfoData

    private static let highlightWords = [
        "day", "civil", "nautical", "astronomical", "night",
        "twilight", "dusk", "dawn",
    ]

    var body: some View {
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
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)

                Text(highlightedText)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let url = URL(string: info.learnMoreURL) {
                    Link(destination: url) {
                        Label("Learn More", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(info.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Twilight vocabulary is tinted, matching the old attributed-string pass.
    // Attributes are set via explicit attribute types: the dynamic-member
    // keypath spelling trips a Sendable error in Swift 6.
    private var highlightedText: AttributedString {
        var attributed = AttributedString(info.text)

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
}

#Preview {
    NavigationStack {
        InfoView(info: .civilTwilight)
    }
}
