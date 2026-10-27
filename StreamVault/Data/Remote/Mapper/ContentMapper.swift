import Foundation

// MARK: - Mapper: DTO → Domain Model
/// Responsible for transforming raw data layer types into clean domain models.
struct ContentMapper {
    static func map(_ dto: ContentDTO) -> Content {
        return Content(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            thumbnailURL: dto.thumbnailURL,
            bannerURL: dto.bannerURL,
            videoURL: dto.videoURL,
            genre: dto.genre,
            year: dto.year,
            rating: dto.rating,
            duration: dto.duration
        )
    }

    static func map(_ dto: HomeResponseDTO) -> HomeScreenData {
        return HomeScreenData(
            heroBanner: map(dto.heroBanner),
            rails: dto.rails.map { rail in
                ContentRail(
                    id: rail.id,
                    title: rail.title,
                    items: rail.items.map { map($0) }
                )
            }
        )
    }
}
