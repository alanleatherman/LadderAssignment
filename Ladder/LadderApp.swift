//
//  LadderApp.swift
//  Ladder
//
//  Created by Andrew Hulsizer on 11/20/24.
//

import SwiftUI

@main
struct LadderApp: App {
    @State private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            FeatsHomeView()
                .inject(environment.appContainer)
                .preferredColorScheme(.dark)
        }
    }
}
