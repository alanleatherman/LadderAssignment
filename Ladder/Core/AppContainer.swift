//
//  AppContainer.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import SwiftData
import Creed_Lite

struct AppContainer {
    let interactors: Interactors
    let repository: FeatsRepositoryProtocol
    let hapticEngine: HapticEngine
    let repCounterAnimator: RepCounterAnimator
    let appState: AppState

    init(interactors: Interactors,
         repository: FeatsRepositoryProtocol,
         appState: AppState,
         hapticEngine: HapticEngine = HapticEngine(),
         repCounterAnimator: RepCounterAnimator = RepCounterAnimator()) {
        self.interactors = interactors
        self.repository = repository
        self.appState = appState
        self.hapticEngine = hapticEngine
        self.repCounterAnimator = repCounterAnimator
    }

    @MainActor
    static func create(with modelContext: ModelContext) -> AppContainer {
        let repository = FeatsRepository(modelContext: modelContext)
        let appState = AppState()
        let interactors = Interactors.live(repository: repository, appState: appState)

        return AppContainer(interactors: interactors, repository: repository, appState: appState)
    }

    struct Interactors {
        let feats: FeatsInteractorProtocol
        let leaderboard: LeaderboardInteractorProtocol
        let featTest: FeatTestInteractorProtocol

        @MainActor
        static func live(repository: FeatsRepositoryProtocol, appState: AppState) -> Self {
            .init(
                feats: FeatsInteractor(repository: repository),
                leaderboard: LeaderboardInteractor(),
                featTest: FeatTestInteractor(repository: repository, appState: appState)
            )
        }
    }
}

// MARK: - Environment Values

private struct ContainerKey: EnvironmentKey {
    @MainActor static let defaultValue: AppContainer = {
        let repo = MockRepository()
        let state = AppState()
        return AppContainer(
            interactors: AppContainer.Interactors(
                feats: FeatsInteractor(repository: repo),
                leaderboard: LeaderboardInteractor(),
                featTest: FeatTestInteractor(repository: repo, appState: state)
            ),
            repository: repo,
            appState: state
        )
    }()
}

private struct InteractorsKey: EnvironmentKey {
    @MainActor static let defaultValue: AppContainer.Interactors = {
        let repo = MockRepository()
        let state = AppState()
        return AppContainer.Interactors(
            feats: FeatsInteractor(repository: repo),
            leaderboard: LeaderboardInteractor(),
            featTest: FeatTestInteractor(repository: repo, appState: state)
        )
    }()
}

extension EnvironmentValues {
    var container: AppContainer {
        get { self[ContainerKey.self] }
        set { self[ContainerKey.self] = newValue }
    }

    var interactors: AppContainer.Interactors {
        get { self[InteractorsKey.self] }
        set { self[InteractorsKey.self] = newValue }
    }
}

// MARK: - Mock Repository for Environment Defaults

@MainActor
private final class MockRepository: FeatsRepositoryProtocol {
    func getMonthlyFeats() async throws -> MonthlyFeats {
        fatalError("MockRepository not intended for actual use")
    }

    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore? {
        return nil
    }

    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {}

    func getFeatCompletions() async -> [FeatCompletion] {
        return []
    }

    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {}

    func clearCache() async throws {}
}

// MARK: - View Extension

extension View {
    func inject(_ container: AppContainer) -> some View {
        return self
            .environment(\.container, container)
            .environment(\.interactors, container.interactors)
            .environment(\.appState, container.appState)
    }
}
