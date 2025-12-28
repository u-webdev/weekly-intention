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

        Group {
        #if os(iOS)
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
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { selectedIndex = weeksBefore }

        #else
        // macOS: explicit navigation instead of an unlabeled TabView picker.
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    selectedIndex = max(0, selectedIndex - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .disabled(selectedIndex <= 0)

                Button {
                    selectedIndex = min(weeks.count - 1, selectedIndex + 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(selectedIndex >= weeks.count - 1)

                Spacer()

                Text(macWeekTitle(for: currentWeekStart(from: weeks)))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            WeekSlide(
                weekStart: currentWeekStart(from: weeks),
                calendar: calendar,
                intentionText: intentionText(for: currentWeekStart(from: weeks))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                beginEdit(weekStart: currentWeekStart(from: weeks))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .onAppear { selectedIndex = weeksBefore }
        #endif
        }
        .sheet(item: editingWeekStartDateItem) { (item: DateItem) in
            EditIntentionSheet(
                weekStart: item.date,
                calendar: calendar,
                text: $draftText,
                onSave: {
                    saveIntention(weekStart: item.date, text: draftText)
                }
            )
            #if os(iOS)
            .presentationDetents([.medium])
            #endif
        }
    }

    private func macWeekTitle(for weekStart: Date) -> String {
        let weekNo = calendar.component(.weekOfYear, from: weekStart)
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        let df = DateFormatter()
        df.calendar = calendar
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")

        return "Week \(weekNo) · \(df.string(from: weekStart)) – \(df.string(from: end))"
    }

    private func currentWeekStartFallback() -> Date {
        startOfWeek(for: Date())
    }

    private func currentWeekStart(from weeks: [Date]) -> Date {
        weeks[safe: selectedIndex] ?? currentWeekStartFallback()
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
