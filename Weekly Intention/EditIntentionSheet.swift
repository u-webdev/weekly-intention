import SwiftUI

#if canImport(WidgetKit)
import WidgetKit
#endif

private let appGroupID = "group.com.uwebury.weeklyintention"
private let currentWeekKey = "currentWeekIntention"
private let widgetKind = "WeeklyIntentionWidget" // must match the Widget `kind`

private func startOfWeek(for date: Date, calendar: Calendar) -> Date {
    let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
}

private func writeCurrentWeekIntentionIfNeeded(_ value: String, weekStart: Date, calendar: Calendar) {
    let currentWeekStart = startOfWeek(for: Date(), calendar: calendar)
    guard calendar.isDate(weekStart, inSameDayAs: currentWeekStart) else { return }

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    UserDefaults(suiteName: appGroupID)?.set(trimmed, forKey: currentWeekKey)

    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    #endif
}

struct EditIntentionSheet: View {
    let weekStart: Date
    let calendar: Calendar

    @Binding var text: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text(rangeTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $text)
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))

                Spacer()
            }
            .padding()
            .navigationTitle("Weekly Intention")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Persist to SwiftData via the parent callback.
                        onSave()

                        // Keep the widget in sync via the shared App Group (only for the current week).
                        writeCurrentWeekIntentionIfNeeded(text, weekStart: weekStart, calendar: calendar)

                        dismiss()
                    }
                }
            }
        }
    }

    private var rangeTitle: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMM d")
        return "\(df.string(from: weekStart)) – \(df.string(from: end))"
    }
}
