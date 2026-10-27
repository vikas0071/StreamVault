import Foundation
import Combine

// MARK: - Home Screen State
enum HomeViewState {
    case idle
    case loading
    case success(HomeScreenData)
    case empty
    case error(String)
}

// MARK: - HomeViewModel
/// Drives the Home screen UI. Communicates with the use case layer.
/// Never imports UIKit – pure business logic + state.
@MainActor
final class HomeViewModel {
    // MARK: - Published State (Combine)
    @Published private(set) var viewState: HomeViewState = .idle

    // MARK: - Dependencies
    private let getHomeContentUseCase: GetHomeContentUseCaseProtocol

    init(getHomeContentUseCase: GetHomeContentUseCaseProtocol) {
        self.getHomeContentUseCase = getHomeContentUseCase
    }

    // MARK: - Intents
    func loadContent() {
        viewState = .loading
        Task {
            do {
                let data = try await getHomeContentUseCase.execute()
                if data.rails.isEmpty {
                    viewState = .empty
                } else {
                    viewState = .success(data)
                }
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
}
