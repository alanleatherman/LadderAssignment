//
//  AppEnvironment.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import OSLog

@MainActor
struct AppEnvironment {
    let option: Option
    let appContainer: AppContainer

    enum Option: String {
        case tests
        case preview
        case production
    }

    var isRunningTests: Bool {
        return option == .tests
    }

    static let current: Option = {
        #if PREVIEW
        return .preview
        #elseif TESTS
        return .tests
        #else
        return .production
        #endif
    }()
}

extension AppEnvironment {
    static func bootstrap(_ optionOverride: AppEnvironment.Option? = nil) -> AppEnvironment {
        let option = optionOverride ?? AppEnvironment.current
        let logger = Logger(subsystem: "com.ladder.app", category: "AppEnvironment")
        logger.info("Current environment: \(option.rawValue)")

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        guard !isRunningTests || option == .tests else {
            fatalError("Cannot setup app environment in test context")
        }

        switch option {
        case .tests:
            return createTestEnvironment()
        case .preview:
            return createPreviewEnvironment()
        case .production:
            return createProductionEnvironment()
        }
    }

    private static func createTestEnvironment() -> AppEnvironment {
        return AppEnvironment(
            option: .tests,
            appContainer: .stub
        )
    }

    private static func createPreviewEnvironment() -> AppEnvironment {
        return AppEnvironment(
            option: .preview,
            appContainer: .preview
        )
    }

    private static func createProductionEnvironment() -> AppEnvironment {
        let interactors = AppContainer.Interactors.live
        let container = AppContainer(interactors: interactors)

        return AppEnvironment(
            option: .production,
            appContainer: container
        )
    }
}
