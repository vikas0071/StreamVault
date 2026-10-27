import Foundation

// MARK: - Repository Protocol (Domain Layer)
/// Defines the contract for fetching content data.
/// The Domain layer depends on this abstraction, not on concrete implementations.
protocol ContentRepositoryProtocol {
    func fetchHomeScreenData() async throws -> HomeScreenData
    func fetchContentDetail(id: String) async throws -> Content
}
