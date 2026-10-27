import UIKit
import Combine

// MARK: - HomeViewController
final class HomeViewController: UIViewController {

    // MARK: - Section & Item types for DiffableDataSource
    private enum Section: Hashable {
        case hero
        case rail(String) // rail title as identifier
    }

    private enum Item: Hashable {
        case hero(String)  // content id
        case card(String)  // content id
    }

    // MARK: - UI
    private var collectionView: UICollectionView!
    private let loadingView = LoadingView()
    private let errorView = ErrorView()

    // MARK: - Data
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var homeData: HomeScreenData?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - ViewModel
    private let viewModel: HomeViewModel

    // MARK: - Init
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:)")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        setupNavigationBar()
        setupCollectionView()
        setupDataSource()
        setupOverlayViews()
        bindViewModel()
        viewModel.loadContent()
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        let logoLabel = UILabel()
        logoLabel.text = "StreamVault"
        logoLabel.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        logoLabel.textColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoLabel)
        navigationItem.backButtonTitle = ""
    }

    // MARK: - Collection View Setup
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "HeroCell")
        collectionView.register(ContentCardCell.self, forCellWithReuseIdentifier: ContentCardCell.reuseIdentifier)
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }
            let snapshot = self.dataSource.snapshot()
            guard sectionIndex < snapshot.sectionIdentifiers.count else { return nil }
            let section = snapshot.sectionIdentifiers[sectionIndex]
            switch section {
            case .hero: return self.makeHeroSection()
            case .rail: return self.makeRailSection()
            }
        }
    }

    private func makeHeroSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(480)),
            subitems: [item]
        )
        return NSCollectionLayoutSection(group: group)
    }

    private func makeRailSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(130), heightDimension: .absolute(210))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10)

        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(130), heightDimension: .absolute(210))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 28, trailing: 16)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }

    // MARK: - DiffableDataSource Setup
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }

            switch item {
            case .hero(let id):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeroCell", for: indexPath)
                // Remove old hero view if recycled
                cell.subviews.forEach { $0.removeFromSuperview() }
                if let content = self.homeData?.heroBanner, content.id == id {
                    let heroBannerView = HeroBannerView(frame: cell.bounds)
                    heroBannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    heroBannerView.configure(with: content)
                    heroBannerView.ctaButton.addTarget(self, action: #selector(self.heroCTATapped), for: .touchUpInside)
                    cell.addSubview(heroBannerView)
                }
                return cell

            case .card(let id):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ContentCardCell.reuseIdentifier,
                    for: indexPath
                ) as? ContentCardCell else { return UICollectionViewCell() }
                if let content = self.findContent(id: id) {
                    cell.configure(with: content)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? SectionHeaderView
            let sections = self?.dataSource.snapshot().sectionIdentifiers
            if let section = sections?[indexPath.section], case .rail(let title) = section {
                header?.configure(title: title)
            }
            return header
        }
    }

    // MARK: - Overlay Views (Loading / Error)
    private func setupOverlayViews() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        view.addSubview(errorView)

        for overlay in [loadingView, errorView] as [UIView] {
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        errorView.retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        loadingView.isHidden = true
        errorView.isHidden = true
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state: state)
            }
            .store(in: &cancellables)
    }

    private func render(state: HomeViewState) {
        switch state {
        case .idle:
            break

        case .loading:
            collectionView.isHidden = true
            errorView.isHidden = true
            loadingView.isHidden = false
            loadingView.startAnimating()

        case .success(let data):
            homeData = data
            loadingView.isHidden = true
            loadingView.stopAnimating()
            errorView.isHidden = true
            collectionView.isHidden = false
            applySnapshot(data: data)

        case .empty:
            loadingView.isHidden = true
            loadingView.stopAnimating()
            collectionView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: "No content available at this time.")

        case .error(let message):
            loadingView.isHidden = true
            loadingView.stopAnimating()
            collectionView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: message)
        }
    }

    private func applySnapshot(data: HomeScreenData) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        // Hero section
        snapshot.appendSections([.hero])
        snapshot.appendItems([.hero(data.heroBanner.id)], toSection: .hero)

        // Rail sections
        for rail in data.rails {
            let section = Section.rail(rail.title)
            snapshot.appendSections([section])
            snapshot.appendItems(rail.items.map { .card($0.id) }, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Helpers
    private func findContent(id: String) -> Content? {
        guard let data = homeData else { return nil }
        for rail in data.rails {
            if let found = rail.items.first(where: { $0.id == id }) { return found }
        }
        return nil
    }

    // MARK: - Actions
    @objc private func heroCTATapped() {
        guard let hero = homeData?.heroBanner else { return }
        navigateToDetail(content: hero)
    }

    @objc private func retryTapped() {
        viewModel.loadContent()
    }

    private func navigateToDetail(content: Content) {
        let vm = DependencyContainer.shared.makeDetailViewModel(content: content)
        let vc = DetailViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .card(let id) = item, let content = findContent(id: id) {
            navigateToDetail(content: content)
        }
    }
}
