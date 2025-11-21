//
//  AppEnvironment.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import SwiftData
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
    static func bootstrap(modelContext: ModelContext, _ optionOverride: AppEnvironment.Option? = nil) -> AppEnvironment {
        configureURLCache()

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        // If tests are running, force test environment
        let option: Option = {
            if isRunningTests {
                return .tests
            }
            return optionOverride ?? AppEnvironment.current
        }()

        let logger = Logger(subsystem: "com.ladder.app", category: "AppEnvironment")
        logger.info("Current environment: \(option.rawValue)")

        switch option {
        case .tests:
            return createTestEnvironment(modelContext: modelContext)
        case .preview:
            return createPreviewEnvironment(modelContext: modelContext)
        case .production:
            return createProductionEnvironment(modelContext: modelContext)
        }
    }

    private static func createTestEnvironment(modelContext: ModelContext) -> AppEnvironment {
        return AppEnvironment(
            option: .tests,
            appContainer: .create(with: modelContext)
        )
    }

    private static func createPreviewEnvironment(modelContext: ModelContext) -> AppEnvironment {
        return AppEnvironment(
            option: .preview,
            appContainer: .create(with: modelContext)
        )
    }

    private static func createProductionEnvironment(modelContext: ModelContext) -> AppEnvironment {
        return AppEnvironment(
            option: .production,
            appContainer: .create(with: modelContext)
        )
    }

    // MARK: - URLCache Configuration

    private static func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB in-memory cache
        let diskCapacity = 100 * 1024 * 1024 // 100 MB disk cache
        let urlCache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity
        )
        URLCache.shared = urlCache
    }
}
