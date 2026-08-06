import SwiftUI

@MainActor
final class ViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selection: Int = 0
    @Published var focusToken = UUID()
    @Published var resetToken = UUID()
    @Published var hoverHighlightArmed = false

    func prepare() {
        query = ""
        selection = 0
        hoverHighlightArmed = false
        focusToken = UUID()
        resetToken = UUID()
    }
}
