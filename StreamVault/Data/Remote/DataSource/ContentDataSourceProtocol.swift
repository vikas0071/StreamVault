import Foundation

// MARK: - Data Source Protocol
/// Abstracts where data comes from (mock JSON, URLSession, etc.)
/// Swapping this implementation does not affect any layer above the Data layer.
protocol ContentDataSourceProtocol {
    func fetchHomeResponse() async throws -> HomeResponseDTO
}
