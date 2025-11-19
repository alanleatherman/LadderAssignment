//
//  FeatCompletion.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class FeatCompletion {
    @Attribute(.unique) var id: UUID
    var featId: String
    var completedAt: Date
    var repCount: Int
    var duration: TimeInterval

    init(featId: String,
         completedAt: Date = Date(),
         repCount: Int,
         duration: TimeInterval) {
        self.id = UUID()
        self.featId = featId
        self.completedAt = completedAt
        self.repCount = repCount
        self.duration = duration
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
