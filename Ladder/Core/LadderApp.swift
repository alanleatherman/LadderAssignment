//
//  LadderApp.swift
//  Ladder
//
//  Created by Andrew Hulsizer on 11/20/24.
//

import SwiftUI
import SwiftData

@main
struct LadderApp: App {
    let modelContainer: ModelContainer
    @State private var environment: AppEnvironment

    @MainActor
    init() {
        do {
            modelContainer = try ModelContainer(
                for: CachedFeat.self, UserBestScore.self, FeatCompletion.self
            )
            environment = AppEnvironment.bootstrap(modelContext: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            FeatsHomeView()
                .inject(environment.appContainer)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
