import UIKit
import AVKit
import Combine

// MARK: - Player View Controller
/// Full-screen video player with custom controls.
final class PlayerViewController: UIViewController {

    // MARK: - UI
    private let playerLayerView = PlayerLayerView()
    private let controlsOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let bufferingLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private var controlsHideTimer: Timer?
    private var isControlsVisible = true
    private var cancellables = Set<AnyCancellable>()
    private var isSliderTracking = false

    // MARK: - ViewModel
    private let viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPlayerLayerView()
        setupControlsOverlay()
        setupLoadingView()
        bindViewModel()
        viewModel.setupPlayer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.teardown()
        controlsHideTimer?.invalidate()
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Player Layer View
    private func setupPlayerLayerView() {
        playerLayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerLayerView)
        NSLayoutConstraint.activate([
            playerLayerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerLayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerLayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerLayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Controls Overlay
    private func setupControlsOverlay() {
        controlsOverlay.translatesAutoresizingMaskIntoConstraints = false
        controlsOverlay.backgroundColor = .clear
        view.addSubview(controlsOverlay)
        NSLayoutConstraint.activate([
            controlsOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            controlsOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Top gradient
        let topGradient = CAGradientLayer()
        topGradient.colors = [UIColor.black.withAlphaComponent(0.7).cgColor, UIColor.clear.cgColor]
        topGradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
        controlsOverlay.layer.addSublayer(topGradient)

        // Bottom gradient
        let bottomGradient = CAGradientLayer()
        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        let h = UIScreen.main.bounds.height
        bottomGradient.frame = CGRect(x: 0, y: h - 120, width: UIScreen.main.bounds.width, height: 120)
        controlsOverlay.layer.addSublayer(bottomGradient)

        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        controlsOverlay.addSubview(closeButton)

        // Title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.text = viewModel.content.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsOverlay.addSubview(titleLabel)

        // Play/Pause
        let playConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
        playPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: playConfig), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        controlsOverlay.addSubview(playPauseButton)

        // Buffering label
        bufferingLabel.text = "Buffering..."
        bufferingLabel.textColor = UIColor(white: 0.8, alpha: 1)
        bufferingLabel.font = .systemFont(ofSize: 13)
        bufferingLabel.translatesAutoresizingMaskIntoConstraints = false
        bufferingLabel.isHidden = true
        controlsOverlay.addSubview(bufferingLabel)

        // Progress slider
        progressSlider.minimumTrackTintColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        progressSlider.maximumTrackTintColor = UIColor(white: 0.4, alpha: 1)
        progressSlider.thumbTintColor = .white
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        controlsOverlay.addSubview(progressSlider)

        // Time labels
        for lbl in [currentTimeLabel, durationLabel] {
            lbl.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
            lbl.textColor = UIColor(white: 0.8, alpha: 1)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            controlsOverlay.addSubview(lbl)
        }
        currentTimeLabel.text = "0:00"
        durationLabel.text = "0:00"

        // Layout
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            bufferingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bufferingLabel.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 12),

            progressSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            progressSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36),

            currentTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 4),

            durationLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            durationLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 4),
        ])
    }

    private func setupLoadingView() {
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.$playerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.handlePlayerState(state) }
            .store(in: &cancellables)

        viewModel.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self, !self.isSliderTracking else { return }
                self.currentTimeLabel.text = self.formatTime(time)
                let dur = self.viewModel.duration
                if dur > 0 {
                    self.progressSlider.value = Float(time / dur)
                }
            }
            .store(in: &cancellables)

        viewModel.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                self?.durationLabel.text = self?.formatTime(dur) ?? "0:00"
            }
            .store(in: &cancellables)

        viewModel.$isBuffering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buffering in
                self?.bufferingLabel.isHidden = !buffering
            }
            .store(in: &cancellables)

        // Attach AVPlayer layer once player is available
        viewModel.$playerState
            .receive(on: DispatchQueue.main)
            .first(where: { if case .ready = $0 { return true }; return false })
            .sink { [weak self] _ in
                guard let self, let player = self.viewModel.player else { return }
                self.playerLayerView.setPlayer(player)
                player.play()
            }
            .store(in: &cancellables)
    }

    private func handlePlayerState(_ state: PlayerState) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            loadingIndicator.isHidden = false
        case .ready:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            setPlayPauseIcon(playing: true)
            scheduleHideControls()
        case .playing:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            setPlayPauseIcon(playing: true)
        case .paused:
            setPlayPauseIcon(playing: false)
            showControls()
        case .buffering:
            break
        case .completed:
            setPlayPauseIcon(playing: false)
            showControls()
        case .error(let msg):
            loadingIndicator.stopAnimating()
            showError(msg)
        }
    }

    // MARK: - Controls Visibility
    private func showControls() {
        controlsHideTimer?.invalidate()
        UIView.animate(withDuration: 0.25) { self.controlsOverlay.alpha = 1 }
        isControlsVisible = true
    }

    private func hideControls() {
        UIView.animate(withDuration: 0.25) { self.controlsOverlay.alpha = 0 }
        isControlsVisible = false
    }

    private func scheduleHideControls() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            guard let self, case .playing = self.viewModel.playerState else { return }
            self.hideControls()
        }
    }

    // MARK: - Actions
    @objc private func handleTap() {
        if isControlsVisible { hideControls() } else { showControls(); scheduleHideControls() }
    }

    @objc private func playPauseTapped() {
        switch viewModel.playerState {
        case .playing:
            viewModel.pause()
        default:
            viewModel.play()
            scheduleHideControls()
        }
    }

    @objc private func sliderTouchBegan() { isSliderTracking = true }

    @objc private func sliderValueChanged() {
        let time = Double(progressSlider.value) * viewModel.duration
        currentTimeLabel.text = formatTime(time)
    }

    @objc private func sliderTouchEnded() {
        isSliderTracking = false
        let time = Double(progressSlider.value) * viewModel.duration
        viewModel.seek(to: time)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Helpers
    private func setPlayPauseIcon(playing: Bool) {
        let name = playing ? "pause.fill" : "play.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
        playPauseButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    deinit {
        controlsHideTimer?.invalidate()
    }
}

// MARK: - PlayerLayerView
/// UIView subclass that hosts AVPlayerLayer, properly sized via layoutSubviews.
final class PlayerLayerView: UIView {
    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }
}
