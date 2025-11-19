//
//  UserBestScore.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class UserBestScore {
    @Attribute(.unique) var id: UUID
    var featId: String
    var repCount: Int
    var achievedAt: Date
    var duration: TimeInterval

    init(featId: String,
         repCount: Int,
         achievedAt: Date = Date(),
         duration: TimeInterval) {
        self.id = UUID()
        self.featId = featId
        self.repCount = repCount
        self.achievedAt = achievedAt
        self.duration = duration
    }

    static func isNewBest(repCount: Int, comparedTo existing: UserBestScore?) -> Bool {
        guard let existing = existing else { return true }
        return repCount > existing.repCount
    }
}
