import SwiftUI
import SwiftData

@main
struct WeeklyIntentionApp: App {

    @StateObject private var appState = AppState()
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
        }
        .modelContainer(modelContainer)

        #if os(macOS)
        .commands {
            CommandMenu("Edit") {
                Button("Search Intentions…") {
                    appState.presentRecall(focusSearch: true)
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
        #endif
    }
}
