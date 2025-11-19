//
//  AppContainer.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import SwiftData

struct AppContainer {
    let interactors: Interactors
    let repository: FeatsRepositoryProtocol
    let hapticEngine: HapticEngine
    let repPhysics: RepCounterPhysics
    let appState: AppState

    init(interactors: Interactors,
         repository: FeatsRepositoryProtocol,
         appState: AppState,
         hapticEngine: HapticEngine = HapticEngine(),
         repPhysics: RepCounterPhysics = RepCounterPhysics()) {
        self.interactors = interactors
        self.repository = repository
        self.appState = appState
        self.hapticEngine = hapticEngine
        self.repPhysics = repPhysics
    }

    @MainActor
    static func create(with modelContext: ModelContext) -> AppContainer {
        let repository = FeatsRepository(modelContext: modelContext)
        let appState = AppState()
        let interactors = Interactors.live(repository: repository, appState: appState)

        return AppContainer(interactors: interactors, repository: repository, appState: appState)
    }

    nonisolated static var preview: AppContainer {
        MainActor.assumeIsolated {
            let container = try! ModelContainer(for: CachedFeat.self, UserBestScore.self, FeatCompletion.self)
            let modelContext = ModelContext(container)
            return create(with: modelContext)
        }
    }

    nonisolated static var stub: AppContainer {
        MainActor.assumeIsolated {
            let container = try! ModelContainer(for: CachedFeat.self, UserBestScore.self, FeatCompletion.self)
            let modelContext = ModelContext(container)
            return create(with: modelContext)
        }
    }

    struct Interactors {
        let feats: FeatsInteractor
        let leaderboard: LeaderboardInteractor
        let featTest: FeatTestInteractor

        @MainActor
        static func live(repository: FeatsRepositoryProtocol, appState: AppState) -> Self {
            .init(
                feats: FeatsInteractor(repository: repository),
                leaderboard: LeaderboardInteractor(),
                featTest: FeatTestInteractor(repository: repository, appState: appState)
            )
        }

        nonisolated static var stub: Self {
            MainActor.assumeIsolated {
                let container = try! ModelContainer(for: CachedFeat.self, UserBestScore.self, FeatCompletion.self)
                let modelContext = ModelContext(container)
                let repository = FeatsRepository(modelContext: modelContext)
                let appState = AppState()

                return .init(
                    feats: FeatsInteractor(repository: repository),
                    leaderboard: LeaderboardInteractor(),
                    featTest: FeatTestInteractor(repository: repository, appState: appState)
                )
            }
        }
    }
}

// MARK: - Environment Values

extension EnvironmentValues {
    @Entry var container: AppContainer = .stub
    @Entry var interactors: AppContainer.Interactors = .stub
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
