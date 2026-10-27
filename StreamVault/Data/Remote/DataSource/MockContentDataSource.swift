import Foundation

// MARK: - Mock Data Source
/// Returns a static JSON response, simulating what a real API would return.
/// To replace with a real API: swap this class with a URLSessionContentDataSource
/// that makes a URLSession request. No other layers need to change.
final class MockContentDataSource: ContentDataSourceProtocol {

    enum DataSourceError: Error, LocalizedError {
        case fileNotFound
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Mock JSON file not found in bundle."
            case .decodingFailed(let error):
                return "Failed to decode mock response: \(error.localizedDescription)"
            }
        }
    }

    func fetchHomeResponse() async throws -> HomeResponseDTO {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8s

        guard let url = Bundle.main.url(forResource: "home_response", withExtension: "json") else {
            throw DataSourceError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(HomeResponseDTO.self, from: data)
        } catch {
            throw DataSourceError.decodingFailed(error)
        }
    }
}
