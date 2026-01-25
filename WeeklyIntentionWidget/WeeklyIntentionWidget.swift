import WidgetKit
import SwiftUI

struct WeeklyIntentionEntry: TimelineEntry {
    let date: Date
    let weekStart: Date
    let text: String
    let updatedAt: Date?
}

struct WeeklyIntentionProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyIntentionEntry {
        WeeklyIntentionEntry(
            date: Date(),
            weekStart: WidgetSharedStore.currentISOWeekStart(),
            text: "Focus on what matters.",
            updatedAt: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyIntentionEntry) -> Void) {
        let snap = WidgetSharedStore.read()
        completion(
            WeeklyIntentionEntry(
                date: Date(),
                weekStart: snap.weekStart,
                text: snap.text,
                updatedAt: snap.updatedAt
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyIntentionEntry>) -> Void) {
        let snap = WidgetSharedStore.read()

        let entry = WeeklyIntentionEntry(
            date: Date(),
            weekStart: snap.weekStart,
            text: snap.text,
            updatedAt: snap.updatedAt
        )

        // Refresh periodically (and also on reloadAllTimelines from the app)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct WeeklyIntentionWidgetView: View {
    var entry: WeeklyIntentionProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weekRangeTitle(from: entry.weekStart))
                .font(.caption)
                .foregroundStyle(.secondary)

            if entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Set your weekly intention")
                    .font(.headline)
            } else {
                Text(entry.text)
                    .font(.headline)
                    .lineLimit(4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var accessoryInlineView: some View {
        Text(shortText(maxLength: 28))
    }

    private var accessoryCircularView: some View {
        Text(shortText(maxLength: 10))
            .font(.caption2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weekly Intention")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(shortText(maxLength: 40))
                .font(.caption)
                .lineLimit(2)
        }
    }

    private var accessoryCornerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Intent")
                .font(.caption2)
            Text(shortText(maxLength: 12))
                .font(.caption2)
                .lineLimit(1)
        }
    }

    var body: some View {
        let view = Group {
            switch family {
            case .accessoryInline:
                accessoryInlineView
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryRectangular:
                accessoryRectangularView
#if os(watchOS)
            case .accessoryCorner:
                accessoryCornerView
#endif
            default:
                content
            }
        }

        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
            view
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            view
        }
    }

    private func weekRangeTitle(from weekStart: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let end = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        let df = DateFormatter()
        df.calendar = cal
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(df.string(from: weekStart)) – \(df.string(from: end))"
    }

    private func shortText(maxLength: Int) -> String {
        let trimmed = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "Set intention"
        let base = trimmed.isEmpty ? fallback : trimmed
        guard base.count > maxLength else { return base }
        let idx = base.index(base.startIndex, offsetBy: maxLength)
        return String(base[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct WeeklyIntentionWidget: Widget {
    let kind: String = "WeeklyIntentionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyIntentionProvider()) { entry in
            WeeklyIntentionWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Intention")
        .description("Shows your current week’s intention.")
        .supportedFamilies(supportedFamilies)
    }
}

private let supportedFamilies: [WidgetFamily] = [
    .systemSmall,
    .systemMedium,
    .systemLarge,
    .accessoryInline,
    .accessoryCircular,
    .accessoryRectangular
#if os(watchOS)
    , .accessoryCorner
#endif
]
