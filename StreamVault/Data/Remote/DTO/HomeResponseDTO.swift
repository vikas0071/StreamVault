import Foundation

// MARK: - DTOs (Data Transfer Objects)
/// Mirror the JSON structure from the API. Decoupled from domain models.

struct HomeResponseDTO: Decodable {
    let heroBanner: ContentDTO
    let rails: [RailDTO]
}

struct RailDTO: Decodable {
    let id: String
    let title: String
    let items: [ContentDTO]
}

struct ContentDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let bannerURL: String
    let videoURL: String
    let genre: String
    let year: Int
    let rating: String
    let duration: String
}
