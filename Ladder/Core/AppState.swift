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

}

// MARK: - Environment Values

@MainActor
private struct AppStateKey: @preconcurrency EnvironmentKey {
    static let defaultValue = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
