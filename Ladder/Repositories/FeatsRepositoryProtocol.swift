//
//  FeatsRepositoryProtocol.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import Creed_Lite

@MainActor
protocol FeatsRepositoryProtocol {
    func getMonthlyFeats() async throws -> MonthlyFeats
    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore?
    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws
    func getFeatCompletions() async -> [FeatCompletion]
    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws
    func clearCache() async throws
}
