import Foundation

// MARK: - Detail Screen ViewModel
@MainActor
final class DetailViewModel {
    let content: Content

    init(content: Content) {
        self.content = content
    }
}
