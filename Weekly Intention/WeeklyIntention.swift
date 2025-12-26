import Foundation
import SwiftData

@Model
final class WeeklyIntention {
    @Attribute(.unique) var weekStart: Date
    var text: String

    init(weekStart: Date, text: String = "") {
        self.weekStart = weekStart
        self.text = text
    }
}
