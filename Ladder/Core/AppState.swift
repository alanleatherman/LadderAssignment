//
//  AppState.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class AppState {
    var lastCompletedFeatId: String?
    var completionTimestamp: Date?

    func notifyFeatCompleted(featId: String) {
        lastCompletedFeatId = featId
        completionTimestamp = Date()
    }

    nonisolated static var stub: AppState {
        MainActor.assumeIsolated {
            AppState()
        }
    }
}

// MARK: - Environment Values

extension EnvironmentValues {
    @Entry var appState: AppState = AppState.stub
}
