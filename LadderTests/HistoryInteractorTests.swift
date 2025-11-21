//
//  HistoryInteractorTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/21/25.
//

import XCTest
import SwiftData
import Creed_Lite
@testable import Ladder

@MainActor
final class HistoryInteractorTests: XCTestCase {

    var interactor: HistoryInteractor!
    var mockRepository: MockHistoryTestRepository!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: CachedFeat.self, UserBestScore.self, FeatCompletion.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        mockRepository = MockHistoryTestRepository(modelContext: context)
        interactor = HistoryInteractor(repository: mockRepository)
    }

    override func tearDown() {
        interactor = nil
        mockRepository = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(interactor.featHistories.isEmpty)
        XCTAssertFalse(interactor.isLoading)
        XCTAssertNil(interactor.error)
    }

    // MARK: - Load History Tests

    func testLoadHistoryWithNoData() async {
        mockRepository.completions = []

        await interactor.loadHistory()

        XCTAssertTrue(interactor.featHistories.isEmpty)
        XCTAssertNil(interactor.error)
        XCTAssertFalse(interactor.isLoading)
    }

    func testLoadHistoryGroupsByFeat() async {
        // Given: Multiple completions for different feats
        mockRepository.completions = [
            FeatCompletion(featId: "feat-1", repCount: 25, duration: 300),
            FeatCompletion(featId: "feat-1", repCount: 30, duration: 300),
            FeatCompletion(featId: "feat-2", repCount: 50, duration: 300)
        ]

        await interactor.loadHistory()

        XCTAssertEqual(interactor.featHistories.count, 2)
        XCTAssertFalse(interactor.isLoading)
    }

    func testLoadHistorySortsByMostRecent() async {
        let olderDate = Date().addingTimeInterval(-3600)
        let newerDate = Date()

        mockRepository.completions = [
            FeatCompletion(featId: "feat-1", completedAt: olderDate, repCount: 25, duration: 300),
            FeatCompletion(featId: "feat-2", completedAt: newerDate, repCount: 30, duration: 300)
        ]

        await interactor.loadHistory()

        // Should be sorted with most recent first
        XCTAssertEqual(interactor.featHistories.first?.id, "feat-2")
    }

    func testRefreshHistory() async {
        mockRepository.completions = [
            FeatCompletion(featId: "feat-1", repCount: 25, duration: 300)
        ]

        await interactor.refreshHistory()

        XCTAssertEqual(interactor.featHistories.count, 1)
        XCTAssertFalse(interactor.isLoading)
    }

    // MARK: - FeatHistory Model Tests

    func testFeatHistoryTotalAttempts() async {
        mockRepository.completions = [
            FeatCompletion(featId: "feat-1", repCount: 25, duration: 300),
            FeatCompletion(featId: "feat-1", repCount: 30, duration: 300),
            FeatCompletion(featId: "feat-1", repCount: 35, duration: 300)
        ]

        await interactor.loadHistory()

        let history = interactor.featHistories.first
        XCTAssertEqual(history?.totalAttempts, 3)
    }

    func testFeatHistoryAverageReps() async {
        mockRepository.completions = [
            FeatCompletion(featId: "feat-1", repCount: 20, duration: 300),
            FeatCompletion(featId: "feat-1", repCount: 30, duration: 300),
            FeatCompletion(featId: "feat-1", repCount: 40, duration: 300)
        ]

        await interactor.loadHistory()

        let history = interactor.featHistories.first
        XCTAssertEqual(history?.averageReps, 30) // (20 + 30 + 40) / 3
    }
}

// MARK: - Mock Repository

class MockHistoryTestRepository: FeatsRepositoryProtocol {
    private let modelContext: ModelContext
    var completions: [FeatCompletion] = []
    var userBests: [String: UserBestScore] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getMonthlyFeats() async throws -> MonthlyFeats {
        // Return mock monthly feats
        let json = """
        {
            "id": "test-month-1",
            "title": "December 2024",
            "subtitle": "Test Month",
            "featured_feat_id": "feat-1",
            "feats": [
                {
                    "id": "feat-1",
                    "name": "1 MIN PUSH-UPS",
                    "description": "Test feat 1",
                    "image_url": "https://example.com/image.jpg",
                    "video_url": "https://example.com/video.mp4",
                    "completion_count": 100,
                    "top_3_users": [],
                    "movement": "Push-ups",
                    "duration_seconds": 60
                },
                {
                    "id": "feat-2",
                    "name": "2 MIN AIR SQUATS",
                    "description": "Test feat 2",
                    "image_url": "https://example.com/image.jpg",
                    "video_url": "https://example.com/video.mp4",
                    "completion_count": 150,
                    "top_3_users": [],
                    "movement": "Air Squats",
                    "duration_seconds": 120
                }
            ]
        }
        """
        return try JSONDecoder().decode(MonthlyFeats.self, from: json.data(using: .utf8)!)
    }

    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore? {
        return userBests[featId.rawValue]
    }

    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        let best = UserBestScore(featId: featId.rawValue, repCount: repCount, duration: duration)
        userBests[featId.rawValue] = best
    }

    func getFeatCompletions() async -> [FeatCompletion] {
        return completions
    }

    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        let completion = FeatCompletion(featId: featId.rawValue, repCount: repCount, duration: duration)
        completions.append(completion)
    }

    func clearCache() async throws {
        // Mock implementation
    }
}
