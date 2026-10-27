// MARK: - Domain Model: HomeScreenData
struct HomeScreenData {
    let heroBanner: Content
    let rails: [ContentRail]
}

struct ContentRail {
    let id: String
    let title: String
    let items: [Content]
}
