import Foundation

// MARK: - Player Events
/// Represents discrete playback lifecycle events.
/// Using an enum ensures type-safety and exhaustive handling.
enum PlayerEvent {
    case playerReady
    case playbackStarted
    case playbackPaused
    case playbackResumed
    case seekPerformed(from: Double, to: Double)
    case bufferingStarted
    case bufferingEnded
    case playbackCompleted
    case playbackError(Error)
    case itemLoadFailed

    var logDescription: String {
        switch self {
        case .playerReady:          return "PLAYER_READY"
        case .playbackStarted:      return "PLAYER_STARTED"
        case .playbackPaused:       return "PLAYER_PAUSED"
        case .playbackResumed:      return "PLAYER_RESUMED"
        case .seekPerformed(let from, let to):
            return "PLAYER_SEEKED: \(String(format: "%.1f", from))s → \(String(format: "%.1f", to))s"
        case .bufferingStarted:     return "PLAYER_BUFFERING_STARTED"
        case .bufferingEnded:       return "PLAYER_BUFFERING_ENDED"
        case .playbackCompleted:    return "PLAYER_COMPLETED"
        case .playbackError(let e): return "PLAYER_ERROR: \(e.localizedDescription)"
        case .itemLoadFailed:       return "PLAYER_ITEM_LOAD_FAILED"
        }
    }
}
