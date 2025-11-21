//
//  FeatsRepository.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import SwiftData
import Creed_Lite
import Dependencies

@MainActor
protocol FeatsRepositoryProtocol {
    func getMonthlyFeats() async throws -> MonthlyFeats
    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore?
    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws
    func getFeatCompletions() async -> [FeatCompletion]
    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws
    func getCachedFeat(for featId: String) async -> CachedFeat?
    func clearCache() async throws
}

@MainActor
final class FeatsRepository: FeatsRepositoryProtocol {
    @Dependency(\.featsClient) private var featsClient

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Monthly Feats

    func getMonthlyFeats() async throws -> MonthlyFeats {
        // Fetch fresh data from network
        // Note: We can't cache the full MonthlyFeats because it's not Codable (from Creed_Lite)
        // For now, always fetch fresh. Individual feats are cached for reference.
        let monthlyFeats = try await featsClient.listMonthlyFeats()

        // Cache individual feats for reference/history
        try await cacheIndividualFeats(monthlyFeats)

        return monthlyFeats
    }

    private func cacheIndividualFeats(_ monthlyFeats: MonthlyFeats) async throws {
        // Don't delete all cached feats - we need them for history from previous months
        // Instead, update existing or insert new ones
        for feat in monthlyFeats.feats {
            let featIdString = feat.id.rawValue
            let descriptor = FetchDescriptor<CachedFeat>(
                predicate: #Predicate { $0.id == featIdString }
            )

            let existingCached = try? modelContext.fetch(descriptor).first

            if let existing = existingCached {
                existing.name = feat.name
                existing.featDescription = feat.description
                existing.imageURLString = feat.imageURL.absoluteString
                existing.videoURLString = feat.videoURL.absoluteString
                existing.movement = feat.movement
                existing.completionCount = feat.completionCount
                existing.cachedAt = Date()
            } else {
                let cached = CachedFeat(
                    id: feat.id.rawValue,
                    name: feat.name,
                    description: feat.description,
                    imageURLString: feat.imageURL.absoluteString,
                    videoURLString: feat.videoURL.absoluteString,
                    movement: feat.movement,
                    completionCount: feat.completionCount
                )
                modelContext.insert(cached)
            }
        }

        try modelContext.save()
    }


    // MARK: - User Best Scores

    func getUserBestScore(for featId: Feat.Id) async -> UserBestScore? {
        let descriptor = FetchDescriptor<UserBestScore>(
            predicate: #Predicate { $0.featId == featId.rawValue },
            sortBy: [SortDescriptor(\.repCount, order: .reverse)]
        )

        let results = try? modelContext.fetch(descriptor)
        return results?.first
    }

    func saveUserBestScore(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        let existing = await getUserBestScore(for: featId)

        // Only save if it's a new best
        guard UserBestScore.isNewBest(repCount: repCount, comparedTo: existing) else {
            return
        }

        let newBest = UserBestScore(
            featId: featId.rawValue,
            repCount: repCount,
            duration: duration
        )

        modelContext.insert(newBest)
        try modelContext.save()
    }

    // MARK: - Feat Completions

    func getFeatCompletions() async -> [FeatCompletion] {
        let descriptor = FetchDescriptor<FeatCompletion>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func saveFeatCompletion(featId: Feat.Id, repCount: Int, duration: TimeInterval) async throws {
        let completion = FeatCompletion(
            featId: featId.rawValue,
            repCount: repCount,
            duration: duration
        )

        modelContext.insert(completion)
        try modelContext.save()

        // Also update user's best score
        try await saveUserBestScore(featId: featId, repCount: repCount, duration: duration)
    }

    // MARK: - Cached Feats

    func getCachedFeat(for featId: String) async -> CachedFeat? {
        let descriptor = FetchDescriptor<CachedFeat>(
            predicate: #Predicate { $0.id == featId }
        )

        let results = try? modelContext.fetch(descriptor)
        return results?.first
    }

    // MARK: - Cache Management

    func clearCache() async throws {
        try modelContext.delete(model: CachedFeat.self)
        try modelContext.save()
    }
}
