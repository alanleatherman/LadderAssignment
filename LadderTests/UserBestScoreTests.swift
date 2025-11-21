//
//  UserBestScoreTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/21/25.
//

import XCTest
@testable import Ladder

final class UserBestScoreTests: XCTestCase {

    // MARK: - isNewBest Tests

    func testIsNewBestWhenNoPreviousBest() {
        let isNew = UserBestScore.isNewBest(repCount: 10, comparedTo: nil)
        XCTAssertTrue(isNew, "Any score should be a new best when there's no previous best")
    }

    func testIsNewBestWhenScoreIsHigher() {
        let existingBest = UserBestScore(featId: "test-feat", repCount: 25, duration: 300)
        let isNew = UserBestScore.isNewBest(repCount: 30, comparedTo: existingBest)
        XCTAssertTrue(isNew, "Score of 30 should beat existing best of 25")
    }

    func testIsNotNewBestWhenScoreIsLower() {
        let existingBest = UserBestScore(featId: "test-feat", repCount: 25, duration: 300)
        let isNew = UserBestScore.isNewBest(repCount: 20, comparedTo: existingBest)
        XCTAssertFalse(isNew, "Score of 20 should not beat existing best of 25")
    }

    func testIsNotNewBestWhenScoreIsEqual() {
        let existingBest = UserBestScore(featId: "test-feat", repCount: 25, duration: 300)
        let isNew = UserBestScore.isNewBest(repCount: 25, comparedTo: existingBest)
        XCTAssertFalse(isNew, "Score of 25 should not beat existing best of 25")
    }

    func testIsNewBestWithZeroScore() {
        let existingBest = UserBestScore(featId: "test-feat", repCount: 10, duration: 300)
        let isNew = UserBestScore.isNewBest(repCount: 0, comparedTo: existingBest)
        XCTAssertFalse(isNew, "Zero score should not beat any existing best")
    }

    func testFirstAttemptWithZeroScore() {
        let isNew = UserBestScore.isNewBest(repCount: 0, comparedTo: nil)
        XCTAssertTrue(isNew, "First attempt with 0 reps is technically a new best (though not very good!)")
    }

    // MARK: - Model Tests

    func testUserBestScoreInitialization() {
        let score = UserBestScore(featId: "test-feat", repCount: 42, duration: 180)

        XCTAssertNotNil(score.id)
        XCTAssertEqual(score.featId, "test-feat")
        XCTAssertEqual(score.repCount, 42)
        XCTAssertEqual(score.duration, 180)
        XCTAssertNotNil(score.achievedAt)
    }

    func testUserBestScoreWithCustomDate() {
        let customDate = Date().addingTimeInterval(-3600)
        let score = UserBestScore(
            featId: "test-feat",
            repCount: 42,
            achievedAt: customDate,
            duration: 180
        )

        XCTAssertEqual(score.achievedAt, customDate)
    }
}
