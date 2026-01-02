import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stored: [WeeklyIntention]
    @Environment(\.scenePhase) private var scenePhase

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
    @State private var showRecall: Bool = false

    #if os(macOS)
    @FocusState private var macContentFocused: Bool
    #endif

    private var currentWeekText: String {
        intentionText(for: startOfWeek(for: Date()))
    }

    private func syncWidgetCacheFromStoreIfNeeded() {
        let currentStart = startOfWeek(for: Date())
        let currentText = intentionText(for: currentStart)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let cached = WidgetCache.read().text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard currentText != cached else { return }
        WidgetCache.writeCurrentWeek(text: currentText, weekStart: currentStart)
    }

    var body: some View {
        let weeks = weekStartsAroundNow()

        Group {
            #if os(iOS)
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button {
                        selectedIndex = max(0, selectedIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedIndex <= 0)

                    Button("Today") {
                        selectedIndex = weeksBefore
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(selectedIndex == weeksBefore)

                    Button {
                        selectedIndex = min(weeks.count - 1, selectedIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedIndex >= weeks.count - 1)

                    Spacer()

                    Button {
                        showRecall = true
                    } label: {
                        Label("Recall", systemImage: "clock.arrow.circlepath")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Recall")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

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
            }
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
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .disabled(selectedIndex <= 0)

                    Button("Today") {
                        selectedIndex = weeksBefore
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("0", modifiers: [.command])
                    .help("Jump to current week (⌘0)")
                    .disabled(selectedIndex == weeksBefore)

                    Button {
                        selectedIndex = min(weeks.count - 1, selectedIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .disabled(selectedIndex >= weeks.count - 1)

                    Spacer()

                    Button("Recall") {
                        showRecall = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Recall past intentions")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                let weekStart = currentWeekStart(from: weeks)
                WeekSlide(
                    weekStart: weekStart,
                    calendar: calendar,
                    intentionText: intentionText(for: weekStart)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    beginEdit(weekStart: weekStart)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    selectedIndex = max(0, selectedIndex - 1)
                case .right:
                    selectedIndex = min(weeks.count - 1, selectedIndex + 1)
                default:
                    break
                }
            }
            .focusable()
            #if os(macOS)
            .focused($macContentFocused)
            .focusEffectDisabled()
            #endif
            .onAppear {
                selectedIndex = weeksBefore
                #if os(macOS)
                macContentFocused = true
                #endif
            }
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
        .sheet(isPresented: $showRecall) {
            RecallSheet(
                calendar: calendar,
                items: stored,
                onPickWeekStart: { picked in
                    if let idx = indexForWeekStart(picked, within: weeks) {
                        selectedIndex = idx
                    }
                    showRecall = false
                },
                onClose: {
                    showRecall = false
                }
            )
        }
        .onAppear {
            syncWidgetCacheFromStoreIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncWidgetCacheFromStoreIfNeeded()
            }
        }
        .onChange(of: currentWeekText) { _, _ in
            // Covers CloudKit sync bringing in data for the current week (no explicit save action).
            syncWidgetCacheFromStoreIfNeeded()
        }
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

    private func indexForWeekStart(_ weekStart: Date, within weeks: [Date]) -> Int? {
        weeks.firstIndex(where: { calendar.isDate($0, inSameDayAs: weekStart) })
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

        // Enforce “one intention per week” in code (CloudKit does not support unique constraints).
        let matches = stored.filter { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }

        if trimmed.isEmpty {
            // If cleared, delete all entries for this week.
            for item in matches {
                modelContext.delete(item)
            }
        } else if let first = matches.first {
            // Update the first matching entry.
            first.text = trimmed

            // Delete any accidental duplicates.
            if matches.count > 1 {
                for dup in matches.dropFirst() {
                    modelContext.delete(dup)
                }
            }
        } else {
            // No entry yet for this week.
            modelContext.insert(WeeklyIntention(weekStart: weekStart, text: trimmed))
        }

        // Keep the widget in sync: update cache ONLY when saving the CURRENT week.
        let currentWeekStart = startOfWeek(for: Date())
        if calendar.isDate(weekStart, inSameDayAs: currentWeekStart) {
            WidgetCache.writeCurrentWeek(text: trimmed, weekStart: currentWeekStart)
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

private struct RecallSheet: View {
    let calendar: Calendar
    let items: [WeeklyIntention]
    let onPickWeekStart: (Date) -> Void
    let onClose: () -> Void

    @State private var searchText: String = ""

    private var sortedItems: [WeeklyIntention] {
        let base = items.sorted { $0.weekStart > $1.weekStart }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedItems.isEmpty {
                    VStack(spacing: 12) {
                        Text(searchText.isEmpty ? "No past intentions yet" : "No matching intentions")
                            .font(.headline)

                        Text("Set an intention for any week, then use Recall to jump back to it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 360)

                        Button("Close") { onClose() }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(sortedItems, id: \.weekStart) { item in
                            Button {
                                onPickWeekStart(item.weekStart)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(weekRangeText(for: item.weekStart))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                                        .font(.body)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Recall")
            .searchable(text: $searchText, prompt: "Search intentions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onClose() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 420)
        #endif

        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    private func weekRangeText(for weekStart: Date) -> String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(df.string(from: weekStart)) – \(df.string(from: end))"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
