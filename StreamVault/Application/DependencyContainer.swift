import Foundation

// MARK: - Dependency Container
/// Wires up the dependency graph. This is the composition root.
/// To switch from mock to real API: change dataSource to URLSessionContentDataSource.
final class DependencyContainer {

    // MARK: - Shared Instance
    static let shared = DependencyContainer()

    // MARK: - Data Layer
    private lazy var contentDataSource: ContentDataSourceProtocol = MockContentDataSource()
    private lazy var contentRepository: ContentRepositoryProtocol = ContentRepository(dataSource: contentDataSource)

    // MARK: - Domain Layer (Use Cases)
    func makeGetHomeContentUseCase() -> GetHomeContentUseCaseProtocol {
        return GetHomeContentUseCase(repository: contentRepository)
    }

    func makeGetContentDetailUseCase() -> GetContentDetailUseCaseProtocol {
        return GetContentDetailUseCase(repository: contentRepository)
    }

    // MARK: - Presentation Layer (ViewModels)
    /// @MainActor required because ViewModel inits are @MainActor-isolated
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(getHomeContentUseCase: makeGetHomeContentUseCase())
    }

    @MainActor
    func makeDetailViewModel(content: Content) -> DetailViewModel {
        return DetailViewModel(content: content)
    }

    @MainActor
    func makePlayerViewModel(content: Content) -> PlayerViewModel {
        return PlayerViewModel(content: content)
    }
}
