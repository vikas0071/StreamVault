import Foundation

// MARK: - Analytics Repository Protocol
/// Separates event logging/tracking responsibility from the ViewModel.
protocol AnalyticsRepositoryProtocol {
    func track(event: PlayerEvent)
}

// MARK: - Analytics Repository Implementation
/// Logs player events. In production, this would send to Firebase, Mixpanel, etc.
final class AnalyticsRepository: AnalyticsRepositoryProtocol {
    func track(event: PlayerEvent) {
        print("[StreamVault Analytics] \(event.logDescription)")
    }
}
