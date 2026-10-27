import Foundation

// MARK: - Use Case: Get Content Detail
protocol GetContentDetailUseCaseProtocol {
    func execute(id: String) async throws -> Content
}

final class GetContentDetailUseCase: GetContentDetailUseCaseProtocol {
    private let repository: ContentRepositoryProtocol

    init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: String) async throws -> Content {
        return try await repository.fetchContentDetail(id: id)
    }
}
