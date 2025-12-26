import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stored: [WeeklyIntention]

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601) // Monday-based
        cal.firstWeekday = 2
        return cal
    }()

    private let weeksBefore = 52
    private let weeksAfter  = 52

    @State private var selectedIndex: Int = 0
    @State private var editingWeekStart: Date?
    @State private var draftText: String = ""

    var body: some View {
        let weeks = weekStartsAroundNow()

        TabView(selection: $selectedIndex) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, weekStart in
                WeekSlide(
                    weekStart: weekStart,
                    calendar: calendar,
                    intentionText: intentionText(for: weekStart)
                )
                .tag(index)
                .contentShape(Rectangle())
                .onTapGesture { beginEdit(weekStart: weekStart) }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
#if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
#else
        // macOS doesn't support the iOS-style paging TabViewStyle.
        .tabViewStyle(.automatic)
#endif
        .onAppear { selectedIndex = weeksBefore }
        .sheet(item: editingWeekStartDateItem) { (item: DateItem) in
            EditIntentionSheet(
                weekStart: item.date,
                calendar: calendar,
                text: $draftText,
                onSave: {
                    saveIntention(weekStart: item.date, text: draftText)
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func weekStartsAroundNow() -> [Date] {
        let currentStart = startOfWeek(for: Date())
        return (-weeksBefore...weeksAfter).compactMap { offset in
            calendar.date(byAdding: .weekOfYear, value: offset, to: currentStart)
        }
    }

    private func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    private func intentionText(for weekStart: Date) -> String {
        stored.first(where: { calendar.isDate($0.weekStart, inSameDayAs: weekStart) })?.text ?? ""
    }

    private func beginEdit(weekStart: Date) {
        draftText = intentionText(for: weekStart)
        editingWeekStart = weekStart
    }

    private func saveIntention(weekStart: Date, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = stored.first(where: { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }) {
            existing.text = trimmed
        } else {
            modelContext.insert(WeeklyIntention(weekStart: weekStart, text: trimmed))
        }

        if trimmed.isEmpty,
           let existing = stored.first(where: { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }) {
            modelContext.delete(existing)
        }
    }

    private struct DateItem: Identifiable {
        let id: Date
        let date: Date
    }

    private var editingWeekStartDateItem: Binding<DateItem?> {
        Binding<DateItem?>(
            get: { editingWeekStart.map { DateItem(id: $0, date: $0) } },
            set: { editingWeekStart = $0?.date }
        )
    }
}
