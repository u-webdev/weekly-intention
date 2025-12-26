import SwiftUI
import SwiftData

@main
struct WeeklyIntentionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WeeklyIntention.self)
    }
}
