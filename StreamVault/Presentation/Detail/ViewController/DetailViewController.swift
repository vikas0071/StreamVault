import UIKit

// MARK: - Detail View Controller
final class DetailViewController: UIViewController {

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        return sv
    }()

    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.1, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let bannerGradientView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let bannerGradientLayer = CAGradientLayer()

    private let genreLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 26, weight: .heavy)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private let metaLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = UIColor(white: 0.5, alpha: 1)
        return lbl
    }()

    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = UIColor(white: 0.85, alpha: 1)
        lbl.numberOfLines = 0
        lbl.lineBreakMode = .byWordWrapping
        return lbl
    }()

    private let playButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶  Play Now", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        btn.layer.cornerRadius = 26
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - ViewModel
    private let viewModel: DetailViewModel
    private var imageTask: Task<Void, Never>?

    // MARK: - Init
    init(viewModel: DetailViewModel) {
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
        title = ""
        setupUI()
        configure(with: viewModel.content)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bannerGradientLayer.frame = bannerGradientView.bounds
    }

    // MARK: - Setup
    private func setupUI() {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Banner
        contentView.addSubview(bannerImageView)
        bannerGradientLayer.colors = [UIColor.clear.cgColor, UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor]
        bannerGradientLayer.locations = [0.45, 1.0]
        bannerGradientView.layer.addSublayer(bannerGradientLayer)
        contentView.addSubview(bannerGradientView)

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.heightAnchor.constraint(equalToConstant: 300),

            bannerGradientView.topAnchor.constraint(equalTo: bannerImageView.topAnchor),
            bannerGradientView.bottomAnchor.constraint(equalTo: bannerImageView.bottomAnchor),
            bannerGradientView.leadingAnchor.constraint(equalTo: bannerImageView.leadingAnchor),
            bannerGradientView.trailingAnchor.constraint(equalTo: bannerImageView.trailingAnchor),
        ])

        // Info stack
        let infoStack = UIStackView(arrangedSubviews: [genreLabel, titleLabel, metaLabel, descriptionLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 10
        infoStack.alignment = .leading
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.setCustomSpacing(4, after: genreLabel)
        infoStack.setCustomSpacing(6, after: titleLabel)
        infoStack.setCustomSpacing(16, after: metaLabel)

        contentView.addSubview(infoStack)
        contentView.addSubview(playButton)

        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: bannerImageView.bottomAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            playButton.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 28),
            playButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            playButton.heightAnchor.constraint(equalToConstant: 52),
            playButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    }

    private func configure(with content: Content) {
        let genreAttr = NSAttributedString(string: content.genre.uppercased(),
                                           attributes: [.kern: CGFloat(1.5)])
        genreLabel.attributedText = genreAttr
        titleLabel.text = content.title
        metaLabel.text = "\(content.year)  •  \(content.rating)  •  \(content.duration)"
        descriptionLabel.text = content.description
        loadBannerImage(from: content.bannerURL)
    }

    private func loadBannerImage(from urlString: String) {
        imageTask?.cancel()
        if let cached = ImageCache.shared.image(for: urlString) {
            bannerImageView.image = cached
            return
        }
        guard let url = URL(string: urlString) else { return }
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                ImageCache.shared.store(image, for: urlString)
                await MainActor.run {
                    UIView.transition(with: self.bannerImageView, duration: 0.3, options: .transitionCrossDissolve) {
                        self.bannerImageView.image = image
                    }
                }
            } catch {}
        }
    }

    // MARK: - Actions
    @objc private func playTapped() {
        let playerVM = DependencyContainer.shared.makePlayerViewModel(content: viewModel.content)
        let playerVC = PlayerViewController(viewModel: playerVM)
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true)
    }

    deinit {
        imageTask?.cancel()
    }
}
