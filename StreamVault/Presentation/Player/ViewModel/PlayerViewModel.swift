import Foundation
import Combine
import AVFoundation

// MARK: - Player State
enum PlayerState {
    case loading
    case ready
    case playing
    case paused
    case buffering
    case completed
    case error(String)
}

// MARK: - PlayerViewModel
@MainActor
final class PlayerViewModel {
    // MARK: - Published
    @Published private(set) var playerState: PlayerState = .loading
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isBuffering: Bool = false

    // MARK: - Public
    let content: Content
    private(set) var player: AVPlayer?

    // MARK: - Private
    private let eventHandler = PlayerEventHandler()
    private let analyticsRepository: AnalyticsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var timeObserverToken: Any?

    // MARK: - Init
    init(content: Content, analyticsRepository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
        self.content = content
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Setup
    func setupPlayer() {
        guard let url = URL(string: content.videoURL) else {
            playerState = .error("Invalid video URL")
            return
        }

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = avPlayer

        // Attach event handler
        eventHandler.attach(to: avPlayer, item: item)

        // Subscribe to events from PlayerEventHandler
        eventHandler.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handlePlayerEvent(event)
            }
            .store(in: &cancellables)

        // Track playback time for progress bar
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let secs = time.seconds
            if secs.isFinite { self.currentTime = secs }
            if let item = avPlayer.currentItem, item.duration.isNumeric {
                self.duration = item.duration.seconds
            }
        }
    }

    // MARK: - Controls
    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func seek(to time: Double) {
        let fromTime = currentTime
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            if finished {
                self?.eventHandler.seekPerformed(from: fromTime, to: time)
            }
        }
    }

    // MARK: - Event Handling
    private func handlePlayerEvent(_ event: PlayerEvent) {
        analyticsRepository.track(event: event)

        switch event {
        case .playerReady:
            playerState = .ready
        case .playbackStarted, .playbackResumed:
            playerState = .playing
            isBuffering = false
        case .playbackPaused:
            playerState = .paused
        case .bufferingStarted:
            isBuffering = true
        case .bufferingEnded:
            isBuffering = false
        case .playbackCompleted:
            playerState = .completed
        case .playbackError(let error):
            playerState = .error(error.localizedDescription)
        case .seekPerformed, .itemLoadFailed:
            break
        }
    }

    // MARK: - Cleanup
    func teardown() {
        eventHandler.detach()
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        cancellables.removeAll()
    }

    deinit {
        // Note: teardown() is called explicitly from VC's viewWillDisappear
    }
}
