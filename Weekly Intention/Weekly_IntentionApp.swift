import SwiftUI
import SwiftData

@main
struct WeeklyIntentionApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var appState = AppState()
    @StateObject private var networkStatus = NetworkStatus()
    @StateObject private var syncStatus = SyncStatus()
    private let modelContainer: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private("iCloud.com.uwebury.weeklyintention")
            )
            self.modelContainer = try ModelContainer(
                for: WeeklyIntention.self,
                configurations: config
            )
            print("✅ SwiftData: CloudKit sync enabled (private DB)")
        } catch {
            fatalError("❌ SwiftData: Failed to create CloudKit-backed ModelContainer. Error: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkStatus)
                .environmentObject(syncStatus)
                .onAppear {
                    syncStatus.handleNetworkChange(isOnline: networkStatus.isOnline)
                }
                .onChange(of: networkStatus.isOnline) { _, newValue in
                    syncStatus.handleNetworkChange(isOnline: newValue)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        syncStatus.handleNetworkChange(isOnline: networkStatus.isOnline)

                        // Mirror current-week intention into widget cache after potential CloudKit sync
                        let calendar = Calendar.current
                        let now = Date()
                        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now

                        Task {
                            do {
                                let descriptor = FetchDescriptor<WeeklyIntention>(
                                    predicate: #Predicate { $0.weekStart >= weekStart && $0.weekStart < weekEnd }
                                )
                                if let current = try modelContainer.mainContext.fetch(descriptor).first {
                                    WidgetSharedStore.writeCurrentWeekIntention(
                                        weekStart: current.weekStart,
                                        text: current.text
                                    )
                                }
                            } catch {
                                print("Widget mirror fetch failed:", error)
                            }
                        }
                    }
                }
        }
        .modelContainer(modelContainer)

        #if os(macOS)
        .commands {
            CommandMenu("Edit") {
                Button("Search Intentions…") {
                    appState.presentRecall(focusSearch: true)
                }
                .disabled(syncStatus.state == .syncing)
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
        #endif
    }
}
