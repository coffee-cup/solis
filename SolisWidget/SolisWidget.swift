import AppIntents
import SwiftUI
import WidgetKit

struct SunEntry: TimelineEntry {
    let data: SunWidgetData
    let theme: SunTheme
    let isPlaceholder: Bool
    var date: Date { data.date }

    init(data: SunWidgetData, theme: SunTheme = .current, isPlaceholder: Bool = false) {
        self.data = data
        self.theme = theme
        self.isPlaceholder = isPlaceholder
    }

    static var placeholder: SunEntry {
        SunEntry(data: preview.data, isPlaceholder: true)
    }

    static var preview: SunEntry {
        let now = Date()
        let zone = TimeZone(identifier: "America/Vancouver")!
        let place = SunWidgetPlace(name: "Vancouver", detail: "Canada", latitude: 49.2827,
                                   longitude: -123.1207, timeZoneIdentifier: zone.identifier)
        let days = SunWidgetData.days(from: now, location: place.coordinate, timeZone: zone)
        return SunEntry(data: .snapshot(at: now, locationName: place.name, timeZone: zone,
                                       days: days))
    }
}

struct SunTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SunEntry { .placeholder }

    func snapshot(for configuration: SunWidgetConfiguration, in context: Context) async -> SunEntry {
        if context.isPreview { return .preview }
        return entries(for: configuration, at: Date()).first!
    }

    func timeline(for configuration: SunWidgetConfiguration, in context: Context) async -> Timeline<SunEntry> {
        let now = Date()
        let entries = entries(for: configuration, at: now)
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60)))
    }

    private func entries(for configuration: SunWidgetConfiguration, at now: Date) -> [SunEntry] {
        let theme = configuration.theme.sunTheme
        guard let place = (configuration.location ?? .followApp).resolvedPlace else {
            return [SunEntry(data: .unknown(at: now), theme: theme)]
        }
        let days = SunWidgetData.days(from: now, location: place.coordinate, timeZone: place.timeZone)
        return SunWidgetData.timelineDates(from: now, days: days).map {
            SunEntry(data: .snapshot(at: $0, locationName: place.name, timeZone: place.timeZone, days: days), theme: theme)
        }
    }
}

// MARK: - Shared appearance

extension EnvironmentValues {
    @Entry var solisWidgetTheme: SunTheme = .classic
}

struct WidgetSky: View {
    let theme: SunTheme
    var body: some View {
        let palette = theme.palette
        LinearGradient(colors: [Color(palette.civil), Color(palette.nautical), Color(palette.astronomical)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(.black.opacity(0.24))
    }
}

struct MovingWidgetSky: View {
    let data: SunWidgetData
    let theme: SunTheme

    var body: some View {
        // Use the same background colours as WidgetSky, stretched around the centre line.
        LinearGradient(stops: data.skyStops.map {
            Gradient.Stop(color: colour(for: $0.type), location: $0.position)
        }, startPoint: UnitPoint(x: 0.5, y: -1), endPoint: UnitPoint(x: 0.5, y: 2))
        .overlay(.black.opacity(0.24))
    }

    private func colour(for type: SunType) -> Color {
        let palette = theme.palette
        switch type {
        case .sunrise, .sunset, .civilDawn, .civilDusk: return Color(palette.civil)
        case .nauticalDawn, .nauticalDusk: return Color(palette.nautical)
        case .astronomicalDawn, .astronomicalDusk, .middleNight: return Color(palette.astronomical)
        }
    }
}

private func muli(_ size: CGFloat) -> Font { .custom("Muli", size: size) }

private func widgetTime(_ date: Date, zone: TimeZone, format: String? = nil) -> String {
    let stored = Defaults.defaults.string(forKey: DefaultKey.timeFormat.description)
    let pattern = format ?? (stored == TimeFormat.hour24.description ? "HH:mm" : "h:mm a")
    return TimeFormatters.timeFormatter(pattern, timeZone: zone).string(from: date).lowercased()
}

private struct WidgetClock: View {
    let date: Date
    let zone: TimeZone
    let size: CGFloat

    var body: some View {
        let is24Hour = Defaults.defaults.string(forKey: DefaultKey.timeFormat.description) == TimeFormat.hour24.description
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(widgetTime(date, zone: zone, format: is24Hour ? "HH:mm" : "h:mm"))
                .font(muli(size)).tracking(-1.5).monospacedDigit()
            if !is24Hour {
                Text(widgetTime(date, zone: zone, format: "a"))
                    .font(muli(size * 0.44)).opacity(0.8)
            }
        }
        .lineLimit(1).minimumScaleFactor(0.65)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetTime(date, zone: zone))
    }
}

private struct WidgetLocationLabel: View {
    let name: String
    var body: some View {
        Label(name, systemImage: "location")
            .font(.system(size: 11, weight: .medium))
            .lineLimit(1).opacity(0.8)
    }
}

private struct WidgetEmptyState: View {
    let hasLocation: Bool
    let locationName: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: hasLocation ? "sun.horizon" : "location")
                .font(.system(size: 22, weight: .light)).widgetAccentable()
            Text(hasLocation ? "No sun event soon" : "Choose a location")
                .font(muli(18))
            Text(hasLocation ? (locationName ?? "") : "Edit this widget or open Solis.")
                .font(.system(size: 11)).opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Sunline

/// A full local day, with sunrise and sunset at their calculated positions.
struct SunlineGraphic: View {
    let data: SunWidgetData
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.solisWidgetTheme) private var theme

    private var accent: Color {
        renderingMode == .fullColor ? Color(theme.palette.riseset) : .white
    }

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(x: 7, y: 8, width: max(0, geometry.size.width - 14),
                              height: max(0, geometry.size.height - 16))
            let point = DayCurve.point(at: data.dayProgress, in: rect, data: data)
            Path { path in
                path.move(to: CGPoint(x: 0, y: rect.midY))
                path.addLine(to: CGPoint(x: geometry.size.width, y: rect.midY))
            }
            .stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            DayCurve(data: data).stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)
            DayCurve(data: data, progress: data.dayProgress)
                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)
                .widgetAccentable()
            Circle().fill(accent.opacity(0.16)).frame(width: 22, height: 22).position(point)
            if data.isDaylight {
                Circle().fill(accent).frame(width: 8, height: 8).position(point).widgetAccentable()
            } else {
                Image(systemName: "moon.fill").font(.system(size: 10))
                    .foregroundStyle(accent).position(point).widgetAccentable()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(data.isDaylight ? "Sun above the horizon" : "Sun below the horizon")
        .accessibilityValue("\(widgetTime(data.date, zone: data.timeZone)) local time")
    }
}

private struct DayCurve: Shape {
    let data: SunWidgetData
    var progress: Double = 1

    static func point(at fraction: Double, in rect: CGRect, data: SunWidgetData) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * fraction,
                y: rect.midY - data.sunlineHeight(at: fraction) * rect.height / 2)
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: Self.point(at: 0, in: rect, data: data))
            for step in 1...120 {
                path.addLine(to: Self.point(at: Double(step) / 120 * progress, in: rect, data: data))
            }
        }
    }
}

struct SunlineContent: View {
    let data: SunWidgetData
    let family: WidgetFamily

    var body: some View {
        if let location = data.locationName {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    WidgetLocationLabel(name: location)
                    Spacer(minLength: 4)
                    Image(systemName: data.isDaylight ? "sun.max" : "moon")
                        .font(.system(size: 12, weight: .medium)).widgetAccentable()
                }
                SunlineGraphic(data: data).frame(maxHeight: .infinity)
                HStack {
                    Text("00")
                    Spacer()
                    Text("12")
                    Spacer()
                    Text("24")
                }
                .font(.system(size: 8, weight: .medium).monospacedDigit())
                .opacity(0.65).accessibilityHidden(true)
                .padding(.bottom, 5)
                if let sunrise = data.sunrise, let sunset = data.sunset {
                    HStack(alignment: .top) {
                        endpoint("Sunrise", date: sunrise, alignment: .leading)
                        Spacer(minLength: 4)
                        if family == .systemMedium {
                            daylightSummary
                            Spacer(minLength: 4)
                        }
                        endpoint("Sunset", date: sunset, alignment: .trailing)
                    }
                    if family == .systemSmall {
                        Text("\(daylightTotal) daylight")
                            .font(.system(size: 10)).opacity(0.75)
                            .frame(maxWidth: .infinity).padding(.top, 5)
                    }
                } else {
                    HStack(alignment: .top) {
                        Text(data.daylight == .allDay ? "Sun above the horizon all day" : "Sun below the horizon all day")
                            .font(.system(size: 11)).opacity(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        daylightSummary
                    }
                }
            }
        } else {
            WidgetEmptyState(hasLocation: false, locationName: nil)
        }
    }

    private func endpoint(_ title: String, date: Date, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title).font(.system(size: 10, weight: .medium)).opacity(0.75)
            Text(widgetTime(date, zone: data.timeZone))
                .font(muli(family == .systemMedium ? 20 : 15)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }

    private var daylightSummary: some View {
        VStack(spacing: 2) {
            Text("Daylight").font(.system(size: 10, weight: .medium)).opacity(0.75)
            Text(daylightTotal).font(muli(family == .systemMedium ? 17 : 14)).monospacedDigit()
            if family == .systemMedium, let change = daylightComparison {
                Text(change).font(.system(size: 9)).opacity(0.65)
            }
        }
        .lineLimit(1).minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }

    private var daylightTotal: String {
        let minutes = Int((data.daylightDuration ?? 0) / 60)
        return minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)m"
    }

    private var daylightComparison: String? {
        guard let change = data.daylightChange else { return nil }
        let minutes = Int(abs(change / 60).rounded())
        guard minutes > 0 else { return abs(change) < 1 ? "Same as yesterday" : "Under 1m change" }
        return "\(change > 0 ? "+" : "−")\(minutes)m from yesterday"
    }
}

// MARK: - Clock and countdown

enum SunWidgetStyle { case clock, countdown, sunline, now }

struct NowContent: View {
    let data: SunWidgetData

    var body: some View {
        if let location = data.locationName {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    WidgetLocationLabel(name: location)
                    Text(data.skyPhase).font(muli(24)).lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 28)
                    if let event = data.nextEvent {
                        Text(event.name).font(.system(size: 12, weight: .medium))
                        Text("in \(Text(event.date, style: .relative))")
                            .font(muli(15)).lineLimit(1).minimumScaleFactor(0.7)
                    } else {
                        Text(data.daylight == .allDay ? "24h of daylight" : "No daylight today")
                            .font(.system(size: 12))
                    }
                }
                HStack(spacing: 8) {
                    Rectangle().fill(.white.opacity(0.65)).frame(height: 1)
                    Circle().frame(width: 5, height: 5)
                }
                .widgetAccentable()
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            WidgetEmptyState(hasLocation: false, locationName: nil)
        }
    }
}

struct EventContent: View {
    let data: SunWidgetData
    let family: WidgetFamily
    let countdown: Bool

    private var event: WidgetSunEvent? { countdown ? data.nextRiseOrSet : data.nextEvent }

    var body: some View {
        if let event, let location = data.locationName {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Label(countdown ? "\(event.name) in" : event.name, systemImage: event.symbol)
                        .font(.system(size: 13, weight: .medium))
                        .widgetAccentable()
                    Spacer(minLength: 8)
                    if countdown {
                        Text(event.date, style: .relative)
                            .font(muli(family == .systemMedium ? 38 : 30))
                            .monospacedDigit().tracking(-1)
                            .lineLimit(1).minimumScaleFactor(0.55)
                        Text("at \(widgetTime(event.date, zone: data.timeZone))")
                            .font(.system(size: 12)).opacity(0.8).padding(.top, 3)
                    } else {
                        WidgetClock(date: event.date, zone: data.timeZone,
                                    size: family == .systemMedium ? 46 : 36)
                        Text("in \(Text(event.date, style: .relative))")
                            .font(.system(size: 12)).opacity(0.8).lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.top, 3)
                    }
                    Spacer(minLength: 8)
                    WidgetLocationLabel(name: location)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if family == .systemMedium {
                    VStack(alignment: .leading, spacing: 8) {
                        if data.dayInterval != nil {
                            SunlineGraphic(data: data)
                                .frame(height: 50)
                        }
                        if let sunrise = data.sunrise, let sunset = data.sunset {
                            summaryRow("sunrise", date: sunrise)
                            summaryRow("sunset", date: sunset)
                        }
                    }
                    .frame(width: 100)
                    .accessibilityElement(children: .combine)
                }
            }
        } else {
            WidgetEmptyState(hasLocation: data.locationName != nil, locationName: data.locationName)
        }
    }

    private func summaryRow(_ symbol: String, date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 12))
            Text(widgetTime(date, zone: data.timeZone)).font(muli(14)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .opacity(0.85)
        .accessibilityLabel("\(symbol == "sunrise" ? "Sunrise" : "Sunset") \(widgetTime(date, zone: data.timeZone))")
    }
}

struct SolisWidgetEntryView: View {
    let entry: SunEntry
    var style: SunWidgetStyle = .clock
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var event: WidgetSunEvent? {
        style == .countdown ? entry.data.nextRiseOrSet : entry.data.nextEvent
    }

    var body: some View {
        Group {
            if entry.isPlaceholder {
                placeholder
            } else {
                content
            }
        }
        .environment(\.solisWidgetTheme, entry.theme)
    }

    @ViewBuilder private var placeholder: some View {
        if family == .accessoryInline {
            Text("Solis").redacted(reason: .placeholder)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 3).frame(width: 66, height: 10)
                if family == .systemSmall || family == .systemMedium {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 5).frame(width: 104, height: 28)
                    RoundedRectangle(cornerRadius: 3).frame(width: 76, height: 10)
                    Spacer(minLength: 0)
                }
                RoundedRectangle(cornerRadius: 3).frame(width: 82, height: 10)
            }
            .foregroundStyle(.white.opacity(0.22))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .unredacted()
            .accessibilityLabel("Loading sun times")
            .containerBackground(for: .widget) {
                if family == .accessoryRectangular {
                    Color.clear
                } else {
                    WidgetSky(theme: entry.theme)
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryInline:
            if let event {
                if style == .countdown {
                    Text("\(event.name) in \(Text(event.date, style: .relative))")
                } else {
                    Text("\(event.name) at \(widgetTime(event.date, zone: entry.data.timeZone))")
                }
            } else {
                Text(entry.data.locationName == nil ? "Solis: choose a location" : "No sun event soon")
            }
        case .accessoryRectangular:
            accessory.containerBackground(for: .widget) { Color.clear }
        default:
            Group {
                if style == .sunline {
                    SunlineContent(data: entry.data, family: family)
                } else if style == .now {
                    NowContent(data: entry.data)
                } else {
                    EventContent(data: entry.data, family: family, countdown: style == .countdown)
                }
            }
            .foregroundStyle(renderingMode == .fullColor ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                if style == .now && entry.data.locationName != nil {
                    MovingWidgetSky(data: entry.data, theme: entry.theme)
                } else {
                    WidgetSky(theme: entry.theme)
                }
            }
        }
    }

    @ViewBuilder private var accessory: some View {
        if let event {
            VStack(alignment: .leading, spacing: 2) {
                Label(style == .countdown ? "\(event.name) in" : event.name, systemImage: event.symbol)
                    .font(.caption.weight(.semibold)).widgetAccentable()
                if style == .countdown {
                    Text(event.date, style: .relative).font(.title3.weight(.medium)).monospacedDigit()
                } else {
                    Text(widgetTime(event.date, zone: entry.data.timeZone)).font(.title2.weight(.medium)).monospacedDigit()
                }
                Text(entry.data.locationName ?? "Solis").font(.caption2)
            }
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(entry.data.locationName == nil ? "Edit widget to choose a location" : "No sun event soon")
                .font(.caption)
        }
    }
}

struct SolisWidget: Widget {
    // Keep the existing kind so installed widgets continue to work.
    let kind = "SolisWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SunWidgetConfiguration.self, provider: SunTimelineProvider()) { entry in
            SolisWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Sun Event")
        .description("Sunrise, sunset, first light, and last light.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

struct SunlineWidget: Widget {
    let kind = "SolisSunline"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SunWidgetConfiguration.self, provider: SunTimelineProvider()) { entry in
            SolisWidgetEntryView(entry: entry, style: .sunline)
        }
        .configurationDisplayName("Sunline")
        .description("Sunrise, sunset, and daylight progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SunCountdownWidget: Widget {
    let kind = "SolisCountdown"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SunWidgetConfiguration.self, provider: SunTimelineProvider()) { entry in
            SolisWidgetEntryView(entry: entry, style: .countdown)
        }
        .configurationDisplayName("Sun Countdown")
        .description("Time until the next sunrise or sunset.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

struct SunNowWidget: Widget {
    let kind = "SolisNow"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SunWidgetConfiguration.self, provider: SunTimelineProvider()) { entry in
            SolisWidgetEntryView(entry: entry, style: .now)
        }
        .configurationDisplayName("Now")
        .description("Sky colours through the day.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct SolisWidgets: WidgetBundle {
    var body: some Widget {
        SolisWidget()
        SunlineWidget()
        SunCountdownWidget()
        SunNowWidget()
    }
}

#Preview("Sunline", as: .systemSmall) { SunlineWidget() } timeline: { SunEntry.preview }
#Preview("Sunline wide", as: .systemMedium) { SunlineWidget() } timeline: { SunEntry.preview }
#Preview("Clock", as: .systemSmall) { SolisWidget() } timeline: { SunEntry.preview }
#Preview("Countdown", as: .systemSmall) { SunCountdownWidget() } timeline: { SunEntry.preview }
#Preview("Countdown wide", as: .systemMedium) { SunCountdownWidget() } timeline: { SunEntry.preview }
#Preview("Lock screen", as: .accessoryRectangular) { SunCountdownWidget() } timeline: { SunEntry.preview }
#Preview("Now", as: .systemSmall) { SunNowWidget() } timeline: { SunEntry.preview }
