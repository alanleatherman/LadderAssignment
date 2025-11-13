//
//  AppContainer.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct AppContainer {
    let interactors: Interactors
    let hapticEngine: HapticEngine
    let repPhysics: RepCounterPhysics

    init(interactors: Interactors = .live,
         hapticEngine: HapticEngine = HapticEngine(),
         repPhysics: RepCounterPhysics = RepCounterPhysics()) {
        self.interactors = interactors
        self.hapticEngine = hapticEngine
        self.repPhysics = repPhysics
    }

    static var preview: AppContainer {
        return MainActor.assumeIsolated {
            let featsInteractor = FeatsInteractor()
            let leaderboardInteractor = LeaderboardInteractor()
            let testExecutionInteractor = TestExecutionInteractor()

            let interactors = Interactors(
                feats: featsInteractor,
                leaderboard: leaderboardInteractor,
                testExecution: testExecutionInteractor
            )

            return AppContainer(interactors: interactors)
        }
    }

    static var stub: AppContainer {
        return MainActor.assumeIsolated {
            return AppContainer(interactors: .stub)
        }
    }

    struct Interactors {
        let feats: FeatsInteractor
        let leaderboard: LeaderboardInteractor
        let testExecution: TestExecutionInteractor

        static var live: Self {
            MainActor.assumeIsolated {
                .init(
                    feats: FeatsInteractor(),
                    leaderboard: LeaderboardInteractor(),
                    testExecution: TestExecutionInteractor()
                )
            }
        }

        static var stub: Self {
            MainActor.assumeIsolated {
                .init(
                    feats: FeatsInteractor(),
                    leaderboard: LeaderboardInteractor(),
                    testExecution: TestExecutionInteractor()
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
    }
}
