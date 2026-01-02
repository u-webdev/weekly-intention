import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetCache {
    static let appGroupID = "group.com.uwebury.weeklyintention"
    static let suite = UserDefaults(suiteName: appGroupID)

    static let keyText = "widget_currentWeek_text"
    static let keyWeekStart = "widget_currentWeek_weekStart"
    static let keyUpdatedAt = "widget_currentWeek_updatedAt"

    static func writeCurrentWeek(text: String, weekStart: Date) {
        guard let suite else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        suite.set(trimmed, forKey: keyText)
        suite.set(weekStart.timeIntervalSince1970, forKey: keyWeekStart)
        suite.set(Date().timeIntervalSince1970, forKey: keyUpdatedAt)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyIntentionWidget")
        #endif
    }

    static func read() -> (text: String, weekStart: Date?, updatedAt: Date?) {
        guard let suite else { return ("", nil, nil) }
        let text = suite.string(forKey: keyText) ?? ""
        let ws = suite.object(forKey: keyWeekStart) as? Double
        let ua = suite.object(forKey: keyUpdatedAt) as? Double
        return (
            text,
            ws.map { Date(timeIntervalSince1970: $0) },
            ua.map { Date(timeIntervalSince1970: $0) }
        )
    }
}
