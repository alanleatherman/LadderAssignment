//
//  AppStateTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/12/25.
//

import XCTest
@testable import Ladder

@MainActor
final class AppStateTests: XCTestCase {

    var appState: AppState!

    override func setUp() {
        appState = AppState()
    }

    override func tearDown() {
        appState = nil
    }

    func testInitialState() {
        XCTAssertNil(appState.lastCompletedFeatId)
        XCTAssertNil(appState.completionTimestamp)
    }

    func testNotifyFeatCompleted() {
        let featId = "test-feat-123"
        let beforeTimestamp = Date()

        appState.notifyFeatCompleted(featId: featId)

        XCTAssertEqual(appState.lastCompletedFeatId, featId)
        XCTAssertNotNil(appState.completionTimestamp)
        XCTAssertGreaterThanOrEqual(appState.completionTimestamp!, beforeTimestamp)
    }

    func testMultipleNotifications() {
        appState.notifyFeatCompleted(featId: "feat-1")
        let firstTimestamp = appState.completionTimestamp

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        appState.notifyFeatCompleted(featId: "feat-2")

        XCTAssertEqual(appState.lastCompletedFeatId, "feat-2")
        XCTAssertNotEqual(appState.completionTimestamp, firstTimestamp)
        XCTAssertGreaterThan(appState.completionTimestamp!, firstTimestamp!)
    }
}
