import AVFoundation
import Combine
import Foundation

// MARK: - Player Event Handler
/// Observes AVPlayer via KVO and notifications.
/// Translates low-level player callbacks into typed PlayerEvent values.
/// Separates AVPlayer observation logic from the ViewController and ViewModel.
final class PlayerEventHandler {

    // MARK: - Published Events
    let eventPublisher = PassthroughSubject<PlayerEvent, Never>()

    // MARK: - Private
    private weak var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var observations: [NSKeyValueObservation] = []
    private var notificationTokens: [NSObjectProtocol] = []
    private var timeObserverToken: Any?
    private var wasPlaying = false
    private var lastSeekTime: Double = 0

    // MARK: - Setup
    func attach(to player: AVPlayer, item: AVPlayerItem) {
        self.player = player
        self.playerItem = item

        observePlayerItem(item)
        observePlayer(player)
        addNotifications(item: item)
    }

    // MARK: - KVO Observations
    private func observePlayerItem(_ item: AVPlayerItem) {
        // 1. Status → player ready / error
        let statusObs = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.eventPublisher.send(.playerReady)
            case .failed:
                let error = item.error ?? NSError(domain: "PlayerEventHandler", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Unknown player error"])
                self.eventPublisher.send(.playbackError(error))
            case .unknown:
                break
            @unknown default:
                break
            }
        }

        // 2. Buffering state
        let bufferObs = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            if item.isPlaybackLikelyToKeepUp {
                self.eventPublisher.send(.bufferingEnded)
            } else {
                self.eventPublisher.send(.bufferingStarted)
            }
        }

        // 3. Buffer empty
        let emptyObs = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty {
                self?.eventPublisher.send(.bufferingStarted)
            }
        }

        observations.append(contentsOf: [statusObs, bufferObs, emptyObs])
    }

    private func observePlayer(_ player: AVPlayer) {
        // 4. Rate → play / pause
        let rateObs = player.observe(\.rate, options: [.new, .old]) { [weak self] player, change in
            guard let self else { return }
            let newRate = change.newValue ?? 0
            let oldRate = change.oldValue ?? 0

            if oldRate == 0 && newRate > 0 {
                if self.wasPlaying {
                    self.eventPublisher.send(.playbackResumed)
                } else {
                    self.eventPublisher.send(.playbackStarted)
                    self.wasPlaying = true
                }
            } else if newRate == 0 && oldRate > 0 {
                self.eventPublisher.send(.playbackPaused)
            }
        }

        observations.append(rateObs)

        // 5. Periodic time observer for seek tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // Track current time for seek delta calculation
            self?.lastSeekTime = time.seconds
        }
    }

    // MARK: - Notifications
    private func addNotifications(item: AVPlayerItem) {
        // Playback completed
        let completedToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.eventPublisher.send(.playbackCompleted)
        }

        // Playback failed
        let failedToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                ?? NSError(domain: "AVPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Playback failed"])
            self?.eventPublisher.send(.playbackError(error))
        }

        notificationTokens = [completedToken, failedToken]
    }

    // MARK: - Seek Event
    /// Call this when a user-initiated seek completes.
    func seekPerformed(from: Double, to: Double) {
        eventPublisher.send(.seekPerformed(from: from, to: to))
    }

    // MARK: - Cleanup
    func detach() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()

        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTokens.removeAll()

        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
        playerItem = nil
    }

    deinit {
        detach()
    }
}
