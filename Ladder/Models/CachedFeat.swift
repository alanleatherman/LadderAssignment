//
//  CachedFeat.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class CachedFeat {
    @Attribute(.unique) var id: String
    var name: String
    var featDescription: String
    var imageURLString: String
    var videoURLString: String
    var movement: String
    var completionCount: Int
    var cachedAt: Date
    
    init(id: String,
         name: String,
         description: String,
         imageURLString: String,
         videoURLString: String,
         movement: String,
         completionCount: Int,
         cachedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.featDescription = description
        self.imageURLString = imageURLString
        self.videoURLString = videoURLString
        self.movement = movement
        self.completionCount = completionCount
        self.cachedAt = cachedAt
    }
    
    // Cache is valid until the end of the current month
    var isStale: Bool {
        let calendar = Calendar.current
        let cachedMonth = calendar.component(.month, from: cachedAt)
        let cachedYear = calendar.component(.year, from: cachedAt)
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())

        return cachedMonth != currentMonth || cachedYear != currentYear
    }
}
