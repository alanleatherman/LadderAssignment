//
//  FeatExtensionsTests.swift
//  LadderTests
//
//  Created by Alan Leatherman on 11/12/25.
//

import XCTest
import Creed_Lite
@testable import Ladder

final class FeatExtensionsTests: XCTestCase {

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

    func testDurationTextExtraction1Min() throws {
        let feat = try makeFeat(name: "1 MIN PUSH-UPS")
        XCTAssertEqual(feat.durationText, "1 min")
    }

    func testDurationTextExtraction3Min() throws {
        let feat = try makeFeat(name: "3 MIN BURPEES")
        XCTAssertEqual(feat.durationText, "3 min")
    }

    func testDurationTextExtraction2MinAirSquats() throws {
        let feat = try makeFeat(name: "2 MIN AIR SQUATS")
        XCTAssertEqual(feat.durationText, "2 min")
    }

    func testDurationTextFallback() throws {
        let feat = try makeFeat(name: "UNKNOWN FEAT")
        XCTAssertEqual(feat.durationText, "5 min")
    }

    func testDurationMinutes1Min() throws {
        let feat = try makeFeat(name: "1 MIN PUSH-UPS")
        XCTAssertEqual(feat.durationMinutes, 1)
    }

    func testDurationMinutes3Min() throws {
        let feat = try makeFeat(name: "3 MIN BURPEES")
        XCTAssertEqual(feat.durationMinutes, 3)
    }

    func testDurationMinutesFallback() throws {
        let feat = try makeFeat(name: "UNKNOWN FEAT")
        XCTAssertEqual(feat.durationMinutes, 5)
    }

    func testDurationWithExtraSpaces() throws {
        let feat = try makeFeat(name: "2  MIN  PUSH-UPS")
        XCTAssertEqual(feat.durationText, "2 min")
        XCTAssertEqual(feat.durationMinutes, 2)
    }

    func testDurationLowercase() throws {
        let feat = try makeFeat(name: "4 min pull-ups")
        XCTAssertEqual(feat.durationText, "4 min")
        XCTAssertEqual(feat.durationMinutes, 4)
    }
}
