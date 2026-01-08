import Foundation
import WidgetKit

enum WidgetSharedStore {
    static let appGroupID = "group.com.uwebury.weeklyintention"

    private static let keyWeekStartISO = "widget.weekStartISO"
    private static let keyIntentionText = "widget.intentionText"
    private static let keyUpdatedAt = "widget.updatedAtISO"

    static func writeCurrentWeekIntention(weekStart: Date, text: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        defaults.set(isoDateString(weekStart), forKey: keyWeekStartISO)
        defaults.set(text, forKey: keyIntentionText)
        defaults.set(isoDateString(Date()), forKey: keyUpdatedAt)

        // Prompt widgets to refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyIntentionWidgetV2")
    }


    static func read() -> Snapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return Snapshot(weekStart: currentISOWeekStart(), text: "", updatedAt: nil)
        }

        let weekStart = parseISODate(defaults.string(forKey: keyWeekStartISO)) ?? currentISOWeekStart()
        let text = defaults.string(forKey: keyIntentionText) ?? ""
        let updatedAt = parseISODate(defaults.string(forKey: keyUpdatedAt))

        return Snapshot(weekStart: weekStart, text: text, updatedAt: updatedAt)
    }

    struct Snapshot {
        let weekStart: Date
        let text: String
        let updatedAt: Date?
    }

    // MARK: - ISO week helpers (Monday-based)

    static func currentISOWeekStart(now: Date = Date()) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        // Start of day to keep it stable
        let startOfDay = cal.startOfDay(for: now)
        let weekday = cal.component(.weekday, from: startOfDay)
        // In ISO8601 calendar: Monday=2 ... Sunday=1
        // Compute delta to Monday
        let delta = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -delta, to: startOfDay) ?? startOfDay
    }

    // MARK: - ISO date formatting

    private static func isoDateString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    private static func parseISODate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }

        // Fallback without fractional seconds
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: str)
    }
}
