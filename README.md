# StreamVault – OTT iOS Application

A production-quality OTT-style iOS application built as a technical assignment demonstrating Clean Architecture, MVVM, UIKit, AVPlayer, and Swift Concurrency.

---

## 🚀 Build & Run

**Requirements:**
- Xcode 15+
- iOS Deployment Target: 16.0+
- No external dependencies (zero third-party libraries)

**Steps:**
1. Clone / open the project: `~/Documents/StreamVault/StreamVault.xcodeproj`
2. Select your target simulator or device (iPhone, iOS 16+)
3. Press **⌘R** to build and run
4. The app fetches mock data with a simulated 0.8s network delay

---

## 📱 Minimum Supported iOS Version

**iOS 16.0**

(Uses `UICollectionViewDiffableDataSource`, `UICollectionViewCompositionalLayout`, `UIButton.Configuration`, and Swift Concurrency `async/await`)

---

## 🏗 Architecture Overview

StreamVault is built on **Clean Architecture** with three distinct layers:

```
Presentation Layer
    └── UIViewController (thin, display-only)
    └── ViewModel (state, intent processing)
    └── UICollectionView (DiffableDataSource + CompositionalLayout)

Domain Layer (pure Swift, no imports)
    └── Domain Models (Content, HomeScreenData, ContentRail)
    └── Use Case Protocols + Implementations
    └── Repository Protocol

Data Layer
    └── DTOs (mirror JSON structure)
    └── Mappers (DTO → Domain Model)
    └── DataSource Protocol + MockContentDataSource
    └── ContentRepository (implements domain protocol)
```

The key principle: **each layer depends only on its inner layer**, never outward. The Domain layer has zero knowledge of UIKit, AVFoundation, or networking.

---

## 📁 Project Structure

```
StreamVault/
├── Application/
│   ├── AppDelegate.swift           # UIWindow setup, root VC wiring
│   └── DependencyContainer.swift  # Composition root / DI
│
├── Domain/
│   ├── Models/
│   │   ├── Content.swift
│   │   └── HomeScreenData.swift
│   ├── Repository/
│   │   └── ContentRepositoryProtocol.swift
│   └── UseCases/
│       ├── GetHomeContentUseCase.swift
│       └── GetContentDetailUseCase.swift
│
├── Data/
│   ├── Remote/
│   │   ├── DataSource/
│   │   │   ├── ContentDataSourceProtocol.swift
│   │   │   └── MockContentDataSource.swift
│   │   ├── DTO/
│   │   │   └── HomeResponseDTO.swift
│   │   └── Mapper/
│   │       └── ContentMapper.swift
│   └── Repository/
│       └── ContentRepository.swift
│
├── Presentation/
│   ├── Common/Views/
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   ├── Home/
│   │   ├── ViewController/HomeViewController.swift
│   │   ├── ViewModel/HomeViewModel.swift
│   │   └── Cells/
│   │       ├── ContentCardCell.swift
│   │       ├── SectionHeaderView.swift
│   │       └── HeroBannerView.swift
│   ├── Detail/
│   │   ├── ViewController/DetailViewController.swift
│   │   └── ViewModel/DetailViewModel.swift
│   └── Player/
│       ├── ViewController/PlayerViewController.swift
│       ├── ViewModel/PlayerViewModel.swift
│       └── EventHandler/
│           ├── PlayerEvent.swift
│           ├── PlayerEventHandler.swift
│           └── AnalyticsRepository.swift
│
└── Resources/
    └── Mock/
        └── home_response.json
```

---

## 📚 Libraries Used

**None.** Zero third-party dependencies. The application uses only Apple frameworks:
- `UIKit` – UI
- `AVFoundation` / `AVKit` – Video playback
- `Combine` – Reactive state binding between ViewModel ↔ ViewController
- `Foundation` – Data, JSON decoding

---

## 🔑 Key Technical & Architectural Decisions

### 1. Clean Architecture + MVVM
- Three strict layers: Presentation, Domain, Data
- The Domain layer contains **zero UIKit/AVFoundation imports** — it's pure Swift
- ViewModels are `@MainActor final class` decorated — ensuring all published state updates happen on the main thread safely

### 2. Dependency Inversion at Every Layer
- `ContentRepositoryProtocol` — Domain defines the contract, Data implements it
- `ContentDataSourceProtocol` — Data layer contract, so the mock can be swapped for URLSession
- `GetHomeContentUseCaseProtocol` — allows mock use cases in testing
- `AnalyticsRepositoryProtocol` — decouples event tracking from the ViewModel

### 3. DiffableDataSource + CompositionalLayout
- `UICollectionViewDiffableDataSource<Section, Item>` powers both the Hero Banner and all content rails
- `UICollectionViewCompositionalLayout` with orthogonal scrolling for rails
- Section enum with associated values: `.hero`, `.rail(String)` — type-safe section identification

### 4. Swift Concurrency (async/await)
- All data fetching uses `async/await`
- `Task { }` is used inside the ViewModel (not the ViewController)
- Image loading in cells uses `Task` with cancellation in `prepareForReuse()`

### 5. Memory Management
- All closures and Combine subscriptions use `[weak self]`
- AVPlayer observers use `NSKeyValueObservation` (auto-invalidated)
- `PlayerEventHandler.detach()` explicitly removes all KVO observers and notification tokens
- `PlayerViewModel.teardown()` is called in `viewWillDisappear` — prevents resource leaks

### 6. No XIBs – Programmatic UI
- All UI is built programmatically (no Storyboards, no XIBs), giving full control
- `Auto Layout` with `NSLayoutConstraint` and `UIStackView`

---

## 🎬 Player Event Handling

### Pipeline
```
AVPlayer (KVO/Notifications)
    ↓
PlayerEventHandler (observes, maps to PlayerEvent enum)
    ↓
PlayerViewModel (handles state transitions, routes to analytics)
    ↓
AnalyticsRepository (logs the event)
    ↓
PlayerViewController (updates UI based on @Published playerState)
```

### Events Implemented (7 total)
| Event | Trigger |
|-------|---------|
| `PLAYER_READY` | `AVPlayerItem.status == .readyToPlay` (KVO) |
| `PLAYER_STARTED` | `AVPlayer.rate` transitions `0 → >0` (KVO) |
| `PLAYER_PAUSED` | `AVPlayer.rate` transitions `>0 → 0` (KVO) |
| `PLAYER_RESUMED` | Subsequent `rate` 0→>0 after first start |
| `PLAYER_SEEKED` | User releases slider, `player.seek(completionHandler:)` callback |
| `PLAYER_BUFFERING_STARTED` | `isPlaybackLikelyToKeepUp == false` or `isPlaybackBufferEmpty == true` (KVO) |
| `PLAYER_BUFFERING_ENDED` | `isPlaybackLikelyToKeepUp == true` (KVO) |
| `PLAYER_COMPLETED` | `AVPlayerItemDidPlayToEndTime` notification |
| `PLAYER_ERROR` | `AVPlayerItemFailedToPlayToEndTime` notification or `.status == .failed` |

### Observer Mechanisms Used
- **KVO** via `NSKeyValueObservation` (`.observe()`) for: `status`, `rate`, `isPlaybackLikelyToKeepUp`, `isPlaybackBufferEmpty`
- **Notifications** for: `AVPlayerItemDidPlayToEndTime`, `AVPlayerItemFailedToPlayToEndTime`
- **Periodic time observer** for current time tracking

### Separation of Responsibilities
- `PlayerEventHandler` — owns all AVPlayer observation, emits typed `PlayerEvent` via `PassthroughSubject`
- `PlayerViewModel` — receives events, manages `PlayerState`, routes to analytics
- `AnalyticsRepository` — terminal event consumer (logs, would send to Firebase/Mixpanel in production)
- `PlayerViewController` — only reacts to `@Published playerState` from ViewModel, zero AVPlayer knowledge

---

## 🔌 Replacing Mock Data with a Real API

This requires changing **only one file** in the Data layer:

```swift
// Current (Mock):
final class MockContentDataSource: ContentDataSourceProtocol {
    func fetchHomeResponse() async throws -> HomeResponseDTO {
        // Returns static JSON from bundle
    }
}

// Replace with:
final class URLSessionContentDataSource: ContentDataSourceProtocol {
    private let session: URLSession
    private let baseURL: URL

    func fetchHomeResponse() async throws -> HomeResponseDTO {
        let url = baseURL.appendingPathComponent("/api/v1/home")
        let (data, response) = try await session.data(from: url)
        // Validate response, decode HomeResponseDTO
        return try JSONDecoder().decode(HomeResponseDTO.self, from: data)
    }
}
```

Then in `DependencyContainer.swift`, change one line:
```swift
// Before:
private lazy var contentDataSource: ContentDataSourceProtocol = MockContentDataSource()

// After:
private lazy var contentDataSource: ContentDataSourceProtocol = URLSessionContentDataSource(baseURL: apiBaseURL)
```

**Zero changes** to: Domain models, Use cases, Repository protocols, ViewModels, ViewControllers.

---

## ⚠️ Known Limitations

1. **Image caching** uses a simple `NSCache` — a production app would use a disk cache (URLCache or SDWebImage)
2. **No unit tests** included (time constraint); the protocol-based architecture makes each layer independently testable
3. **Player orientation** forces landscape — a production player would handle orientation more gracefully
4. **No authentication layer** — the architecture supports adding it in the Data layer without touching Domain/Presentation
5. **Thumbnail images** use TMDB CDN — require network connectivity to display (gracefully degrades to placeholder)

---

## 🔄 Application State Flow

```
Data Source → Repository → Use Case → ViewModel (@Published ViewState) → ViewController
                                                    ↓
                                          .loading → show LoadingView
                                          .success → apply DiffableDataSource snapshot
                                          .empty   → show EmptyView
                                          .error   → show ErrorView with retry button
```

---

*Built with Swift 5.9, UIKit, Combine, AVFoundation. No third-party libraries.*
