import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isRecallPresented: Bool = false

    /// Set to true right before presenting Recall so the search field can autofocus.
    @Published var shouldFocusRecallSearch: Bool = false

    func presentRecall(focusSearch: Bool = true) {
        shouldFocusRecallSearch = focusSearch
        isRecallPresented = true
    }
}
