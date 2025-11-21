//
//  FeatTestInteractorTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/12/25.
//

import XCTest
import SwiftData
import Creed_Lite
@testable import Ladder

@MainActor
final class FeatTestInteractorTests: XCTestCase {

    var interactor: FeatTestInteractor!
    var mockRepository: MockFeatsRepository!
    var appState: AppState!

    override func setUp() async throws {
        appState = AppState()
        let container = try ModelContainer(for: CachedFeat.self, UserBestScore.self, FeatCompletion.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        mockRepository = MockFeatsRepository(modelContext: context)
        interactor = FeatTestInteractor(repository: mockRepository, appState: appState)
    }

    override func tearDown() {
        interactor = nil
        mockRepository = nil
        appState = nil
    }

    // MARK: - Test Initial State

    func testInitialState() {
        XCTAssertEqual(interactor.repCount, 0)
        XCTAssertFalse(interactor.isActive)
        XCTAssertNil(interactor.startTime)
        XCTAssertEqual(interactor.elapsedTime, 0)
        XCTAssertEqual(interactor.phase, .ready)
        XCTAssertNil(interactor.lastMilestone)
    }

    // MARK: - Test Rep Counter

    func testIncrementRep() {
        // Start test first
        interactor.startTest()

        interactor.incrementRep()
        XCTAssertEqual(interactor.repCount, 1)

        interactor.incrementRep()
        XCTAssertEqual(interactor.repCount, 2)
    }

    func testDecrementRep() {
        interactor.startTest()
        interactor.incrementRep()
        interactor.incrementRep()

        interactor.decrementRep()
        XCTAssertEqual(interactor.repCount, 1)
    }

    func testCannotDecrementBelowZero() {
        interactor.startTest()
        interactor.decrementRep()
        XCTAssertEqual(interactor.repCount, 0)
    }

    func testCannotIncrementWhenInactive() {
        interactor.incrementRep()
        XCTAssertEqual(interactor.repCount, 0)
    }

    // MARK: - Test Milestones

    func testMilestoneAtEvery10Reps() {
        interactor.startTest()

        // No milestone before 10
        for _ in 1...9 {
            interactor.incrementRep()
        }
        XCTAssertNil(interactor.lastMilestone)

        // Milestone at 10
        interactor.incrementRep()
        XCTAssertEqual(interactor.lastMilestone, 10)

        // Milestone at 20
        for _ in 11...20 {
            interactor.incrementRep()
        }
        XCTAssertEqual(interactor.lastMilestone, 20)
    }

    // MARK: - Test Phase Transitions

    func testStartTest() {
        interactor.startTest()

        XCTAssertEqual(interactor.phase, .active)
        XCTAssertTrue(interactor.isActive)
        XCTAssertNotNil(interactor.startTime)
        XCTAssertEqual(interactor.repCount, 0)
    }

    func testPauseTest() {
        interactor.startTest()
        interactor.pauseTest()

        XCTAssertEqual(interactor.phase, .paused)
        XCTAssertFalse(interactor.isActive)
    }

    func testResumeTest() {
        interactor.startTest()
        interactor.pauseTest()
        interactor.resumeTest()

        XCTAssertEqual(interactor.phase, .active)
        XCTAssertTrue(interactor.isActive)
    }

    func testCompleteTest() async {
        interactor.startTest()
        interactor.incrementRep()
        interactor.incrementRep()
        interactor.incrementRep()

        interactor.completeTest()

        XCTAssertEqual(interactor.phase, .complete(repCount: 3))
        XCTAssertFalse(interactor.isActive)
    }

    func testReset() {
        interactor.startTest()
        interactor.incrementRep()
        interactor.incrementRep()

        interactor.reset()

        XCTAssertEqual(interactor.repCount, 0)
        XCTAssertFalse(interactor.isActive)
        XCTAssertNil(interactor.startTime)
        XCTAssertEqual(interactor.elapsedTime, 0)
        XCTAssertEqual(interactor.phase, .ready)
        XCTAssertNil(interactor.lastMilestone)
    }

    // MARK: - Test Duration Extraction

    func testDurationExtractionFromFeatName() throws {
        let feat1Min = try makeFeat(name: "1 MIN PUSH-UPS")
        interactor.configure(with: feat1Min)
        XCTAssertEqual(interactor.testDuration, 60)

        let feat3Min = try makeFeat(name: "3 MIN BURPEES")
        interactor.configure(with: feat3Min)
        XCTAssertEqual(interactor.testDuration, 180)
    }
}

// MARK: - Mock Repository

class MockFeatsRepository: FeatsRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getMonthlyFeats() async throws -> MonthlyFeats {
        fatalError("Not needed for these tests")
    }

    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore? {
        return nil
    }

    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        // Mock implementation - do nothing
    }

    func getFeatCompletions() async -> [FeatCompletion] {
        return []
    }

    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        // Mock implementation - do nothing
    }

    func getCachedFeat(for featId: String) async -> CachedFeat? {
        return nil
    }

    func clearCache() async throws {
        // Mock implementation - do nothing
    }
}

// MARK: - Test Helpers

extension FeatTestInteractorTests {
    func makeFeat(name: String) throws -> Feat {
        let json = """
        {
            "id": "test-feat",
            "name": "\(name)",
            "description": "Test feat",
            "image_url": "https://example.com/image.jpg",
            "video_url": "https://example.com/video.mp4",
            "completion_count": 0,
            "top_3_users": [],
            "movement": "Test Movement",
            "duration_seconds": 60
        }
        """
        return try JSONDecoder().decode(Feat.self, from: json.data(using: .utf8)!)
    }
}
