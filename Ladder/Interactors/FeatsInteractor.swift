//
//  FeatsInteractor.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import Dependencies
import Creed_Lite
import Observation

@MainActor
@Observable
final class FeatsInteractor {
    @ObservationIgnored
    private let repository: FeatsRepositoryProtocol

    var monthlyFeats: MonthlyFeats?
    var isLoading: Bool = false
    var error: FeatsError?
    var userBestScores: [String: UserBestScore] = [:]
    var completedFeatIds: Set<String> = []

    init(repository: FeatsRepositoryProtocol) {
        self.repository = repository
    }

    func loadMonthlyFeats() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            monthlyFeats = try await repository.getMonthlyFeats()
            await loadUserData()
        } catch {
            self.error = .loadFailed(error)
        }
    }

    func loadUserData() async {
        guard let feats = monthlyFeats?.feats else { return }

        // Load user's best scores for all feats
        for feat in feats {
            if let bestScore = await repository.getUserBestScore(for: feat.id) {
                userBestScores[feat.id.rawValue] = bestScore
                completedFeatIds.insert(feat.id.rawValue)
            }
        }
    }

    func getUserBest(for featId: Feat.Id) -> UserBestScore? {
        return userBestScores[featId.rawValue]
    }

    func hasCompleted(_ featId: Feat.Id) -> Bool {
        return completedFeatIds.contains(featId.rawValue)
    }

    func refreshFeats() async {
        await loadMonthlyFeats()
    }
}

enum FeatsError: LocalizedError {
    case loadFailed(Error)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Unable to load challenges. Pull to refresh."
        case .notFound:
            return "Challenge not found."
        }
    }
}
