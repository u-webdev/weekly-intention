import SwiftUI

struct EditIntentionSheet: View {
    let weekStart: Date
    let calendar: Calendar

    @Binding var text: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text(rangeTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $text)
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))

                Spacer()
            }
            .padding()
            .navigationTitle("Weekly Intention")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }

    private var rangeTitle: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMM d")
        return "\(df.string(from: weekStart)) – \(df.string(from: end))"
    }
}
