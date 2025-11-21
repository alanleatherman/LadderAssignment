//
//  FeatsInteractorTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/21/25.
//

import XCTest
import SwiftData
import Creed_Lite
@testable import Ladder

@MainActor
final class FeatsInteractorTests: XCTestCase {

    var interactor: FeatsInteractor!
    var mockRepository: MockFeatsTestRepository!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: CachedFeat.self, UserBestScore.self, FeatCompletion.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        mockRepository = MockFeatsTestRepository(modelContext: context)
        interactor = FeatsInteractor(repository: mockRepository)
    }

    override func tearDown() {
        interactor = nil
        mockRepository = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(interactor.monthlyFeats)
        XCTAssertFalse(interactor.isLoading)
        XCTAssertNil(interactor.error)
        XCTAssertTrue(interactor.userBestScores.isEmpty)
        XCTAssertTrue(interactor.completedFeatIds.isEmpty)
    }

    // MARK: - Load Monthly Feats Tests

    func testLoadMonthlyFeatsSuccess() async {
        mockRepository.shouldSucceed = true

        await interactor.loadMonthlyFeats()

        XCTAssertNotNil(interactor.monthlyFeats)
        XCTAssertEqual(interactor.monthlyFeats?.feats.count, 2)
        XCTAssertNil(interactor.error)
        XCTAssertFalse(interactor.isLoading)
    }

    func testLoadMonthlyFeatsFailure() async {
        mockRepository.shouldSucceed = false

        await interactor.loadMonthlyFeats()

        XCTAssertNil(interactor.monthlyFeats)
        XCTAssertNotNil(interactor.error)
        XCTAssertFalse(interactor.isLoading)
    }

    func testLoadMonthlyFeatsLoadsUserData() async {
        // Given: Repository has user bests
        mockRepository.shouldSucceed = true
        mockRepository.userBests = [
            "feat-1": UserBestScore(featId: "feat-1", repCount: 50, duration: 60)
        ]

        await interactor.loadMonthlyFeats()

        // Then: User data should be loaded
        XCTAssertEqual(interactor.userBestScores.count, 1)
        XCTAssertEqual(interactor.userBestScores["feat-1"]?.repCount, 50)
        XCTAssertTrue(interactor.completedFeatIds.contains("feat-1"))
    }

    // MARK: - Load User Data Tests

    func testLoadUserDataPopulatesBestScores() async {
        mockRepository.shouldSucceed = true
        mockRepository.userBests = [
            "feat-1": UserBestScore(featId: "feat-1", repCount: 30, duration: 60),
            "feat-2": UserBestScore(featId: "feat-2", repCount: 45, duration: 120)
        ]

        await interactor.loadMonthlyFeats()

        XCTAssertEqual(interactor.userBestScores.count, 2)
        XCTAssertEqual(interactor.userBestScores["feat-1"]?.repCount, 30)
        XCTAssertEqual(interactor.userBestScores["feat-2"]?.repCount, 45)
    }

    func testLoadUserDataMarksFeatsAsCompleted() async {
        mockRepository.shouldSucceed = true
        mockRepository.userBests = [
            "feat-1": UserBestScore(featId: "feat-1", repCount: 25, duration: 60)
        ]

        await interactor.loadMonthlyFeats()

        XCTAssertTrue(interactor.completedFeatIds.contains("feat-1"))
        XCTAssertFalse(interactor.completedFeatIds.contains("feat-2"))
    }

    // MARK: - Get User Best Tests

    func testGetUserBestReturnsCorrectScore() async {
        mockRepository.shouldSucceed = true
        mockRepository.userBests = [
            "feat-1": UserBestScore(featId: "feat-1", repCount: 42, duration: 60)
        ]

        await interactor.loadMonthlyFeats()

        let best = interactor.getUserBest(for: Feat.Id(rawValue: "feat-1"))
        XCTAssertNotNil(best)
        XCTAssertEqual(best?.repCount, 42)
    }

    func testGetUserBestReturnsNilWhenNotFound() async {
        mockRepository.shouldSucceed = true
        await interactor.loadMonthlyFeats()

        let best = interactor.getUserBest(for: Feat.Id(rawValue: "nonexistent"))
        XCTAssertNil(best)
    }

    // MARK: - Has Completed Tests

    func testHasCompletedReturnsTrueForCompletedFeat() async {
        mockRepository.shouldSucceed = true
        mockRepository.userBests = [
            "feat-1": UserBestScore(featId: "feat-1", repCount: 25, duration: 60)
        ]

        await interactor.loadMonthlyFeats()

        XCTAssertTrue(interactor.hasCompleted(Feat.Id(rawValue: "feat-1")))
    }

    func testHasCompletedReturnsFalseForUncompletedFeat() async {
        mockRepository.shouldSucceed = true
        await interactor.loadMonthlyFeats()

        XCTAssertFalse(interactor.hasCompleted(Feat.Id(rawValue: "feat-2")))
    }

    // MARK: - Refresh Tests

    func testRefreshReloadsData() async {
        mockRepository.shouldSucceed = true

        // Initial load
        await interactor.loadMonthlyFeats()
        XCTAssertNotNil(interactor.monthlyFeats)

        // Modify repository state
        mockRepository.userBests["feat-2"] = UserBestScore(featId: "feat-2", repCount: 100, duration: 120)

        // Refresh
        await interactor.refreshFeats()

        XCTAssertEqual(interactor.userBestScores.count, 1)
        XCTAssertEqual(interactor.userBestScores["feat-2"]?.repCount, 100)
    }
}

// MARK: - Mock Repository

class MockFeatsTestRepository: FeatsRepositoryProtocol {
    private let modelContext: ModelContext
    var shouldSucceed = true
    var userBests: [String: UserBestScore] = [:]
    var completions: [FeatCompletion] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getMonthlyFeats() async throws -> MonthlyFeats {
        if !shouldSucceed {
            throw NSError(domain: "TestError", code: -1)
        }

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

    func getCachedFeat(for featId: String) async -> CachedFeat? {
        return nil
    }

    func clearCache() async throws {
        // Mock implementation
    }
}
