// MARK: - Domain Model: Content
/// Pure domain model, independent of any data or presentation concerns.
struct Content {
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
