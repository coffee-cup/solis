//
//  SolisWidget.swift
//  SolisWidget
//
//  WidgetKit replacement for the old Today extension. Shows the next sun
//  event (first light, sunrise, sunset, last light) for the current location
//  saved by the app in the shared app group.
//

import WidgetKit
import SwiftUI

struct SunEntry: TimelineEntry {
    let date: Date
    let eventName: String?
    let eventDate: Date?
    let locationName: String?

    static let placeholder = SunEntry(
        date: Date(),
        eventName: "Sunset",
        eventDate: Date().addingTimeInterval(60 * 90),
        locationName: "Vancouver"
    )

    static var unknown: SunEntry {
        SunEntry(date: Date(), eventName: nil, eventDate: nil, locationName: nil)
    }
}

struct SunTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> SunEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SunEntry) -> ()) {
        completion(context.isPreview ? .placeholder : entry(at: Date()))
    }

    // One entry per upcoming event so the widget flips to the next event the
    // moment one passes; WidgetKit reloads the timeline after the last entry.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SunEntry>) -> ()) {
        guard let location = SunLocation.getCurrentLocation() else {
            let timeline = Timeline(
                entries: [SunEntry.unknown],
                policy: .after(Date().addingTimeInterval(60 * 60)))
            completion(timeline)
            return
        }

        let suntimes = SunLogic.todayTomorrow(location)
        let eventDates = SunLogic.futureTimes(suntimes)
            .map { $0.date! }
            .sorted()

        var entries = [entry(at: Date(), suntimes: suntimes)]
        for date in eventDates {
            entries.append(entry(at: date.addingTimeInterval(1), suntimes: suntimes))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date, suntimes: [Suntime]? = nil) -> SunEntry {
        guard let location = SunLocation.getCurrentLocation() else {
            return .unknown
        }

        let times = suntimes ?? SunLogic.todayTomorrow(location)
        let future = times.filter { $0.date.timeIntervalSince(date) > 0 }
        guard let next = SunLogic.nextEvent(future) else {
            return .unknown
        }

        return SunEntry(
            date: date,
            eventName: next.type.event,
            eventDate: next.date,
            locationName: SunLocation.getCurrentLocationName())
    }
}

// MARK: - Styling

// Re-read per render so the widget follows the theme selected in the app;
// the app reloads widget timelines on theme change.
var solisGradient: LinearGradient {
    let palette = SunTheme.current.palette
    return LinearGradient(
        colors: [Color(palette.civil), Color(palette.nautical)],
        startPoint: .top,
        endPoint: .bottom)
}

func muli(_ size: CGFloat, light: Bool = false) -> Font {
    .custom(light ? "Muli-Light" : "Muli", size: size)
}

func formattedTime(_ date: Date) -> String {
    TimeFormatters.formatter12h(TimeZone.ReferenceType.local).string(from: date)
        .replacingOccurrences(of: "AM", with: "am")
        .replacingOccurrences(of: "PM", with: "pm")
}

// MARK: - Views

struct SolisWidgetEntryView: View {
    var entry: SunEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryRectangular:
            rectangular
        default:
            home
        }
    }

    var inline: some View {
        Group {
            if let name = entry.eventName, let date = entry.eventDate {
                Text("\(name) \(formattedTime(date))")
            } else {
                Text("Solis – open app")
            }
        }
    }

    var rectangular: some View {
        Group {
            if let name = entry.eventName, let date = entry.eventDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                    Text(formattedTime(date))
                    Text(date, style: .relative)
                        .font(.caption)
                        .opacity(0.8)
                }
            } else {
                Text("Open Solis to set your location")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    var home: some View {
        Group {
            if let name = entry.eventName, let date = entry.eventDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(muli(15, light: true))
                        .opacity(0.85)
                    Text(formattedTime(date))
                        .font(muli(family == .systemMedium ? 32 : 24))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Text(date, style: .relative)
                            .font(muli(12, light: true))
                            .opacity(0.7)
                            .lineLimit(1)
                        if family == .systemMedium, let location = entry.locationName {
                            Spacer(minLength: 8)
                            Text(location)
                                .font(muli(12, light: true))
                                .opacity(0.7)
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Text("😔 I don't know")
                    Text("where you are")
                }
                .font(muli(14, light: true))
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { solisGradient }
    }
}

@main
struct SolisWidget: Widget {
    let kind: String = "SolisWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunTimelineProvider()) { entry in
            SolisWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Sun Event")
        .description("Shows the upcoming sunrise, sunset, first light, or last light.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

#Preview("Small", as: .systemSmall) {
    SolisWidget()
} timeline: {
    SunEntry.placeholder
    SunEntry.unknown
}

#Preview("Medium", as: .systemMedium) {
    SolisWidget()
} timeline: {
    SunEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    SolisWidget()
} timeline: {
    SunEntry.placeholder
}
