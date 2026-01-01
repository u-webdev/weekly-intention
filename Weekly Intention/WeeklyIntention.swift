import Foundation
import SwiftData

@Model
final class WeeklyIntention {
    // ✅ CloudKit needs default values for non-optional attributes
    var weekStart: Date = Date.distantPast
    var text: String = ""

    // Optional but recommended: stable identity for CloudKit
    var id: UUID = UUID()

    init(weekStart: Date, text: String = "") {
        self.weekStart = weekStart
        self.text = text
    }
}
