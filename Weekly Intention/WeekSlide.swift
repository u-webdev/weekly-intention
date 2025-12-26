import SwiftUI

struct WeekSlide: View {
    let weekStart: Date
    let calendar: Calendar
    let intentionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(weekRangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Week \(weekNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            if intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Set intention")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(intentionText)
                    .font(.largeTitle.weight(.semibold))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var weekNumber: Int {
        calendar.component(.weekOfYear, from: weekStart)
    }

    private var weekRangeText: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(df.string(from: weekStart)) – \(df.string(from: end))"
    }
}
