import Foundation

// MARK: - Repository Implementation (Data Layer)
/// Implements ContentRepositoryProtocol using a data source.
/// The domain layer only knows about the protocol, not this concrete class.
final class ContentRepository: ContentRepositoryProtocol {
    private let dataSource: ContentDataSourceProtocol
    private var cachedHomeData: HomeResponseDTO?

    init(dataSource: ContentDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchHomeScreenData() async throws -> HomeScreenData {
        let dto = try await dataSource.fetchHomeResponse()
        cachedHomeData = dto
        return ContentMapper.map(dto)
    }

    func fetchContentDetail(id: String) async throws -> Content {
        // Use cached data if available, otherwise fetch
        if let cached = cachedHomeData {
            let allItems = cached.rails.flatMap { $0.items } + [cached.heroBanner]
            if let item = allItems.first(where: { $0.id == id }) {
                return ContentMapper.map(item)
            }
        }
        // Fallback: re-fetch
        let dto = try await dataSource.fetchHomeResponse()
        let allItems = dto.rails.flatMap { $0.items } + [dto.heroBanner]
        guard let item = allItems.first(where: { $0.id == id }) else {
            throw NSError(domain: "ContentRepository", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Content not found for id: \(id)"])
        }
        return ContentMapper.map(item)
    }
}
