import UIKit

// MARK: - Hero Banner View
final class HeroBannerView: UIView {

    // MARK: - UI
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.1, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientLayer = CAGradientLayer()

    private let genreLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        lbl.textColor = .white
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = UIColor(white: 0.8, alpha: 1)
        lbl.numberOfLines = 3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let metaLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = UIColor(white: 0.6, alpha: 1)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    let ctaButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶  View Details", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 22
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var imageTask: Task<Void, Never>?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Setup
    private func setupUI() {
        addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Gradient overlay
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.6).cgColor,
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        layer.addSublayer(gradientLayer)

        // Content stack
        let stack = UIStackView(arrangedSubviews: [genreLabel, titleLabel, descriptionLabel, metaLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
            ctaButton.widthAnchor.constraint(equalToConstant: 160)
        ])

        stack.setCustomSpacing(12, after: metaLabel)
    }

    // MARK: - Configure
    func configure(with content: Content) {
        // Spaced genre text
        let genreText = NSAttributedString(
            string: content.genre.uppercased(),
            attributes: [.kern: CGFloat(2.0)]
        )
        genreLabel.attributedText = genreText
        titleLabel.text = content.title
        descriptionLabel.text = content.description
        metaLabel.text = "\(content.year)  •  \(content.rating)  •  \(content.duration)"
        loadImage(from: content.bannerURL)
    }

    private func loadImage(from urlString: String) {
        imageTask?.cancel()
        if let cached = ImageCache.shared.image(for: urlString) {
            backgroundImageView.image = cached
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
                    UIView.transition(with: self.backgroundImageView, duration: 0.3, options: .transitionCrossDissolve) {
                        self.backgroundImageView.image = image
                    }
                }
            } catch {}
        }
    }

    deinit {
        imageTask?.cancel()
    }
}
