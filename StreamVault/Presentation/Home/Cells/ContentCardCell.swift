import UIKit

// MARK: - Content Card Cell (UICollectionViewCell)
final class ContentCardCell: UICollectionViewCell {
    static let reuseIdentifier = "ContentCardCell"

    // MARK: - UI Components
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.15, alpha: 1)
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.isUserInteractionEnabled = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .white
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let ratingLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 10, weight: .medium)
        lbl.textColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var gradientLayer: CAGradientLayer?
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
        gradientLayer?.frame = gradientView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        ratingLabel.text = nil
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.1, alpha: 1)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(titleLabel)

        // Gradient overlay on image
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        gradient.locations = [0.5, 1.0]
        gradientView.layer.addSublayer(gradient)
        self.gradientLayer = gradient

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.4),

            gradientView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),

            ratingLabel.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -8),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
        ])
    }

    // MARK: - Configure
    func configure(with content: Content) {
        titleLabel.text = content.title
        ratingLabel.text = content.rating
        loadImage(from: content.thumbnailURL)
    }

    private func loadImage(from urlString: String) {
        if let cached = ImageCache.shared.image(for: urlString) {
            thumbnailImageView.image = cached
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
                    self.thumbnailImageView.image = image
                }
            } catch {}
        }
    }
}

// MARK: - Simple In-Memory Image Cache
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
