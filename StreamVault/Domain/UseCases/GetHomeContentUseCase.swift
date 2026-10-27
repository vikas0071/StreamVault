import Foundation

// MARK: - Use Case: Get Home Content
/// Encapsulates the business logic for retrieving home screen data.
/// Depends on the repository protocol, not on any concrete implementation (Dependency Inversion).
protocol GetHomeContentUseCaseProtocol {
    func execute() async throws -> HomeScreenData
}

final class GetHomeContentUseCase: GetHomeContentUseCaseProtocol {
    private let repository: ContentRepositoryProtocol

    init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> HomeScreenData {
        return try await repository.fetchHomeScreenData()
    }
}
