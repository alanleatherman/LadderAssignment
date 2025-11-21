# Ladder - Feats of Strength

A modern iOS fitness challenge application built with SwiftUI, leveraging the latest iOS frameworks and architectural patterns.

<img width="301" height="655" alt="Simulator Screenshot - iPhone 17 Pro - 2025-11-19 at 18 39 47" src="https://github.com/user-attachments/assets/a311e950-c681-4c1c-ad05-a2902562a7d9" />
<img width="301" height="655" alt="Simulator Screenshot - iPhone 17 Pro - 2025-11-19 at 18 39 53" src="https://github.com/user-attachments/assets/0c08edf5-5eef-454c-b0e4-ed93726799d9" />
<img width="301" height="655" alt="Simulator Screenshot - iPhone 17 Pro - 2025-11-19 at 18 40 09" src="https://github.com/user-attachments/assets/79d3f2cf-b93f-4b83-8c73-e00e35b6c1bb" />

---

## Assignment Approach

### Screen Selection
I implemented all screens from the Figma designs plus an additional History & PRs page. The decision to build all screens was driven by wanting to demonstrate:
- End-to-end feature development capabilities
- How different parts of the app communicate and share state
- A complete user journey from discovery to completion to tracking progress

The bonus History page was added to give users a way to track their personal records and progression over time, which felt like a natural extension of the "Results" pillar mentioned in the assignment.

### Key Improvements Over Original Designs

**1. Performance Optimization**
- Custom `CachedAsyncImage` with imgix CDN optimization reducing bandwidth by 95%
- Persistent URLCache (100MB disk, 50MB memory) for instant image loading
- Tab state persistence eliminating unnecessary data reloads
- Optimized image sizes (200px thumbnails, 400px cards, 800px details)

**2. Enhanced UX**
- Shimmer loading states instead of spinners for modern, polished feel
- Pull-to-refresh without jarring full-screen loading overlays
- Smooth video playback with proper lifecycle management
- Breathing animation during countdown for better user guidance
- Haptic feedback for milestone achievements

**3. Data Persistence**
- History works across months by persisting cached feat data
- User progress tracked locally with SwiftData
- Smart caching strategy that updates instead of deletes

**4. Architecture & Testability**
- Clean architecture with clear separation of concerns
- Protocol-based repository pattern for easy testing
- Comprehensive unit test coverage (interactors, business logic)
- Observable framework for reactive UI updates

### Challenges & Learnings

**Most Challenging:**
- Implementing proper tab state persistence without causing memory leaks or stale data
- Managing cached feat data across months while keeping history functional
- Optimizing image loading for smooth scrolling in image-heavy feeds
- Video playback lifecycle management to prevent resource exhaustion

**Most Interesting:**
- Building the custom `CachedAsyncImage` with automatic imgix URL optimization
- Designing the caching strategy for feat metadata persistence
- Implementing the breathing animation with SwiftUI animations

**Easiest:**
- Basic SwiftUI layouts and navigation
- SwiftData model setup
- Integration with Creed-Lite library

### Prioritization Strategy

**Phase 1: Core User Flow (Day 1)**
1. Feats home feed with video cards
2. Feat detail view with statistics
3. Test execution with timer and rep counter
4. Basic data persistence

**Phase 2: Polish & Features (Day 2)**
1. Leaderboard implementation
2. Loading states and error handling
3. Animations and haptics
4. Top performers display

**Phase 3: Optimization & testing (Days 3)**
1. Custom image caching solution
2. Tab state persistence
3. Performance profiling and improvements
4. Pull-to-refresh UX refinement
5. History & PRs page (bonus feature)
6. Comprehensive unit tests
7. Code cleanup and documentation
8. README and architecture documentation

### What I'd Do With More Time
- Implement proper error recovery and retry mechanisms
- Add offline mode with request queuing
- Build analytics tracking infrastructure
- Create more granular loading states
- Add accessibility improvements (VoiceOver, Dynamic Type)
- Implement proper authentication flow
- Add video recording for form checking
- Build social features (friends, sharing achievements)

---

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
│   ├── HistoryInteractor
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
- State management (AppState and other state directly observable to the Views)
- Data fetching and persistence (via the FeatsRepository)
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
- `CachedFeat`: Monthly feat metadata (persists across months)
- `UserBestScore`: Personal records per feat
- `FeatCompletion`: Completed challenge history

**Key Improvement**: Cached feats are now updated instead of deleted, allowing history to display properly even for feats from previous months.

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

#### 5. **History & PRs**
- Personal records and completion history
- Expandable cards with detailed statistics
- Per-feat metrics:
  - Personal Record (PR)
  - Total attempts
  - Average reps
  - Leaderboard rank
- Recent attempts list (up to 5 shown)
- Pull-to-refresh support
- Persistent across months (cached feat data)
- Optimized thumbnail images

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

#### 4. **Optimized Image Caching with CachedAsyncImage**
Custom image loader with persistent caching and imgix CDN optimization:
```swift
CachedAsyncImage(url: imageURL, size: .thumbnail) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
```

Features:
- **URLCache integration**: 50MB memory, 100MB disk cache
- **Automatic imgix optimization**: Resizes images at CDN level
  - `.thumbnail` (200x200) for avatars
  - `.card` (400x400) for feat cards
  - `.detail` (800x800) for full views
- **Smart URL parameters**: `?w=200&h=200&fit=crop&q=80&auto=format,compress`
- **Persistent caching**: Images survive app restarts
- **Graceful degradation**: Works with any URL, optimizes imgix URLs

Benefits:
- **95% smaller downloads**: 2-5MB images → 10-100KB
- **Instant cache hits**: No re-downloading on tab switches
- **Smooth scrolling**: Pre-sized images load instantly
- **Automatic LRU eviction**: Oldest images removed when cache fills

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
- **Optimized image loading**: Custom caching reduces bandwidth by 95%
- **Tab state persistence**: No data reloading when switching tabs
- **Smart cache management**: URLCache with 100MB limit + automatic eviction
- **imgix CDN optimization**: Images resized server-side before download
- **SwiftData**: Efficient caching and querying for user data
- **Persistent feat cache**: History works across months without API calls
- **Videos auto-play**: Proper lifecycle management prevents memory leaks
- **LazyVStack**: Efficient list rendering with on-demand loading
- **Background Tasks**: Non-blocking async operations

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
│   ├── HistoryInteractor.swift      # History & PRs logic
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
│   ├── History/                     # History & PRs
│   │   └── HistoryView.swift
│   └── Shared/
│       ├── Components/              # Reusable UI
│       └── Modifiers/               # ViewModifiers
│           └── ShimmerModifier.swift
├── Utilities/
│   ├── CachedAsyncImage.swift       # Optimized image caching
│   ├── HapticEngine.swift           # Haptic feedback
│   └── RepCounterAnimator.swift     # Animation utilities
└── LadderApp.swift                  # App entry point

LadderTests/
├── FeatTestInteractorTests.swift    # Test execution interactor tests
├── FeatsInteractorTests.swift       # Feat list interactor tests
├── HistoryInteractorTests.swift     # History interactor tests
├── UserBestScoreTests.swift         # User best score logic tests
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
