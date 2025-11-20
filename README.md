# Ladder - Feats of Strength

A modern iOS fitness challenge application built with SwiftUI, leveraging the latest iOS frameworks and architectural patterns.

## Architecture

### Overview

Ladder follows a **clean architecture** approach with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│   (Views, View Models, UI Components)       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│          Interactors Layer                  │
│   (Business Logic, State Management)        │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│        Repository Layer                     │
│   (Data Access, Caching, Persistence)       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│         Data Layer                          │
│   (SwiftData Models, Network, Local DB)     │
└─────────────────────────────────────────────┘
```

### Key Architectural Components

#### 1. **Dependency Injection via AppContainer**
```swift
AppContainer
├── Interactors
│   ├── FeatsInteractor
│   ├── LeaderboardInteractor
│   └── FeatTestInteractor
├── Repository (FeatsRepository)
├── AppState (Observable state)
├── HapticEngine
└── RepCounterAnimator
```

All dependencies are injected through `AppContainer`, providing:
- **Testability**: Easy to swap with mocks
- **Single source of truth**: Centralized dependency management
- **Type safety**: Compile-time dependency checking

#### 2. **Interactors (Business Logic)**

Interactors are `@Observable` classes that manage:
- Business logic
- State management
- Data fetching and persistence
- Coordination between layers

**Example: FeatTestInteractor**
```swift
@MainActor
@Observable
final class FeatTestInteractor {
    var repCount: Int = 0
    var phase: TestPhase = .ready
    var lastMilestone: Int? = nil

    func incrementRep() { /* ... */ }
    func completeTest() { /* ... */ }
}
```

#### 3. **Repository Pattern**

Abstracts data access behind protocols:
```swift
@MainActor
protocol FeatsRepositoryProtocol {
    func getMonthlyFeats() async throws -> MonthlyFeats
    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore?
    func saveFeatCompletion(...) async throws
}
```

Benefits:
- Swappable implementations (mock for tests, real for production)
- Centralized caching logic
- Clean separation from business logic

#### 4. **SwiftData for Persistence**

Local caching and user data storage:
- `CachedFeat`: Monthly feat metadata
- `UserBestScore`: Personal records
- `FeatCompletion`: Completed challenge history

#### 5. **AppState for Cross-Feature Communication**

Observable state container for app-wide events:
```swift
@Observable
class AppState {
    var lastCompletedFeatId: String?
    var completionTimestamp: Date?
}
```

Views observe `AppState` and react to changes without tight coupling.

---

## Functionality

### Core Features

#### 1. **Feats Home Feed**
- Vertical paging video cards
- Auto-playing looping videos with shimmer loading states
- Dynamic "Challenge of the Month" badge
- Personal record (PR) badges
- Completion statistics
- Top 3 user avatars with retry logic

#### 2. **Feat Detail**
- Full exercise video with looping playback
- "Your Best" score display
- Movement stats (duration, completions, movement type)
- Top performers preview
- Instructions and "How It Works" section
- Context-aware CTA: "START TEST" or "TRY TO BEAT YOUR SCORE"

#### 3. **Leaderboard**
- Time filter (This Week / All Time)
- User position card with rank, reps, and achievement badges
- Top 3 / Top 10 / #1 crown indicators
- "To Beat" count for motivation
- Your position highlighted at bottom if not in top placements
- Pull-to-refresh

#### 4. **Feat Test Execution**
- 3-second countdown
- Real-time timer with pause/resume
- Rep counter with +/- buttons
- Milestone tracking (every 10 reps)
- Breathing guide animation during countdown
- Auto-completion when time expires
- Results saved to local database

---

## Technical Highlights

### Modern Swift & SwiftUI

#### 1. **Swift Concurrency**
```swift
// Async/await throughout
func loadMonthlyFeats() async {
    monthlyFeats = try await repository.getMonthlyFeats()
}

// Structured concurrency
Task { @MainActor in
    try? await Task.sleep(for: .seconds(2))
}
```

#### 2. **Observation Framework**
All state management uses `@Observable` instead of legacy `ObservableObject`:
```swift
@Observable
final class FeatsInteractor {
    var monthlyFeats: MonthlyFeats?
    var isLoading: Bool = false
}
```

Views automatically update when observed properties change.

#### 3. **SwiftData**
Modern replacement for Core Data:
```swift
@Model
final class UserBestScore {
    var featId: String
    var repCount: Int
    var achievedAt: Date
}
```

#### 4. **Modern AsyncImage with Retry Logic**
All avatar images use proper phase handling:
```swift
AsyncImage(url: user.imageURL) { phase in
    switch phase {
    case .empty: /* loading state */
    case .success(let image): /* show image */
    case .failure: /* show fallback icon */
    }
}
```

#### 5. **Environment-based Dependency Injection**
```swift
@Environment(\.container) private var container
@Environment(\.appState) private var appState
```

Clean, SwiftUI-native dependency access.

---

## Pros of This Direction

### 1. **Scalability**
- Clear separation of concerns allows features to grow independently
- Easy to add new feat types, challenges, or social features
- Repository pattern allows backend swapping (API, local, mock)

### 2. **Testability**
- Protocol-based repositories enable easy mocking
- Pure interactor logic isolated from UI
- Unit tests for business logic without UI dependencies
- See `LadderTests/` for examples

### 3. **Maintainability**
- Single Responsibility Principle throughout
- Views are declarative and stateless
- Business logic centralized in interactors
- Consistent patterns across codebase

### 4. **Modern Swift Best Practices**
- `@Observable` instead of `ObservableObject`
- Swift Concurrency (async/await, actors) instead of callbacks
- SwiftData instead of Core Data
- Structured views with extracted subviews
- Shimmer loading states for better UX

### 5. **Performance**
- SwiftData provides efficient caching and querying
- Videos auto-play with proper lifecycle management
- LazyVStack for efficient list rendering
- Background Tasks for non-blocking operations

### 6. **Developer Experience**
- Type-safe dependency injection
- Compile-time error checking
- Xcode Previews-friendly architecture
- Clear file organization by feature

---

## Project Structure

```
Ladder/
├── Core/
│   ├── AppContainer.swift           # DI container
│   ├── AppEnvironment.swift         # Environment setup
│   ├── AppState.swift               # App-wide observable state
│   ├── Models/                      # SwiftData models
│   ├── Repositories/                # Data access layer
│   └── Extensions/                  # Swift extensions
├── Interactors/
│   ├── FeatsInteractor.swift        # Feat list logic
│   ├── LeaderboardInteractor.swift  # Leaderboard logic
│   └── FeatTestInteractor.swift     # Test execution logic
├── Presentation/
│   ├── FeatsHome/                   # Home feed
│   │   ├── FeatsHomeView.swift
│   │   └── Components/
│   │       └── FeatCardView.swift
│   ├── FeatDetail/                  # Detail view
│   │   └── FeatDetailView.swift
│   ├── Leaderboard/                 # Leaderboard
│   │   ├── LeaderboardView.swift
│   │   └── Components/
│   ├── FeatTest/                    # Test execution
│   │   ├── FeatTestView.swift
│   │   └── Components/
│   └── Shared/
│       ├── Components/              # Reusable UI
│       └── Modifiers/               # ViewModifiers
│           └── ShimmerModifier.swift
└── LadderApp.swift                  # App entry point

LadderTests/
├── FeatTestInteractorTests.swift    # Interactor tests
├── AppStateTests.swift              # State tests
└── FeatExtensionsTests.swift        # Extension tests
```

---

## Setup & Running

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `Ladder.xcodeproj` in Xcode
3. Select a simulator or device
4. Run (⌘R)

### Running Tests
```bash
# Command line
xcodebuild test -scheme Ladder -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode
⌘U
```

---

## Key Design Decisions

### 1. **No Combine**
Using `@Observable` + SwiftUI's reactive system instead of Combine for:
- Simpler mental model
- Better performance
- Native SwiftUI integration
- Less boilerplate

### 2. **No NotificationCenter for Internal Events**
Using observable properties instead:
```swift
// Before: NotificationCenter.post(name: .repMilestone)
// After:
var lastMilestone: Int? = nil  // Views observe this
```

Benefits: Type-safe, testable, no stringly-typed APIs.

### 3. **State Ownership**
Views own UI-specific state (like `selectedFeat`), interactors own business state (like `monthlyFeats`).

### 4. **Shimmer over Spinners**
Loading states use shimmer effects instead of progress views for:
- Modern, polished look
- Better perceived performance
- Consistency with contemporary apps

### 5. **Video Playback on Feed**
Auto-playing videos create engaging, dynamic feed similar to modern social apps.

---

## Future Enhancements

### Technical
- [ ] Add network layer with proper error handling
- [ ] Implement proper authentication
- [ ] Add analytics tracking
- [ ] Offline-first architecture with sync
- [ ] Push notifications for challenges

### Features
- [ ] Social features (friends, sharing)
- [ ] Custom challenges
- [ ] Achievement system
- [ ] Progress tracking over time
- [ ] Video recording for form checking
- [ ] Community leaderboards

### Testing
- [ ] Snapshot tests for UI
- [ ] Integration tests for flows
- [ ] Performance benchmarks

---

## Dependencies

- **Creed-Lite**: Provides feat models and API types
- **SwiftData**: Local persistence
- **AVKit**: Video playback

---

## License

[Add your license here]

---

## Contributors

Created by Alan Leatherman

---

## Notes

This app showcases modern iOS development practices including:
- Clean architecture
- Dependency injection
- SwiftUI best practices
- Swift concurrency
- Observable framework
- SwiftData
- Comprehensive unit testing

The codebase prioritizes:
- **Readability**: Clear, self-documenting code
- **Maintainability**: Easy to modify and extend
- **Testability**: Comprehensive test coverage
- **Performance**: Efficient data handling and UI rendering
