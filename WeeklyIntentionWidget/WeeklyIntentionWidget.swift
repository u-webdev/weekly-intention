//
//  WeeklyIntentionWidget.swift
//  WeeklyIntentionWidget
//
//  Created by Uwe Bury on 30.12.25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), intention: "Set this week’s intention")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let text = WidgetCache.read().text.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(SimpleEntry(date: Date(), intention: text))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let text = WidgetCache.read().text.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = SimpleEntry(date: Date(), intention: text)

        // We rely on the app to trigger reloads when the cache changes.
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let intention: String
}

struct WeeklyIntentionWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        let shown = entry.intention.isEmpty ? "Set this week’s intention" : entry.intention

        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Intention")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(shown)
                .font(.headline)
                .lineLimit(6)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct WeeklyIntentionWidget: Widget {
    let kind: String = "WeeklyIntentionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                WeeklyIntentionWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WeeklyIntentionWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Weekly Intention")
        .description("Shows your current week’s intention.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    WeeklyIntentionWidget()
} timeline: {
    SimpleEntry(date: .now, intention: "Calm focus. One thing at a time.")
    SimpleEntry(date: .now, intention: "Be kind to myself.")
}
