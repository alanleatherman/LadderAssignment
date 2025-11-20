//
//  HistoryInteractor.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/19/25.
//

import Foundation
import Observation
import Creed_Lite

struct FeatHistory: Identifiable {
    let id: String
    let featName: String
    let movement: String
    let imageURLString: String
    let attempts: [FeatCompletion]
    let personalRecord: UserBestScore?

    var totalAttempts: Int {
        attempts.count
    }

    var averageReps: Int {
        guard !attempts.isEmpty else { return 0 }
        let total = attempts.reduce(0) { $0 + $1.repCount }
        return total / attempts.count
    }
}

@MainActor
protocol HistoryInteractorProtocol: AnyObject {
    var featHistories: [FeatHistory] { get set }
    var isLoading: Bool { get set }
    var error: HistoryError? { get set }

    func loadHistory() async
    func refreshHistory() async
}

@MainActor
@Observable
final class HistoryInteractor: HistoryInteractorProtocol {
    @ObservationIgnored
    private let repository: FeatsRepositoryProtocol

    var featHistories: [FeatHistory] = []
    var isLoading: Bool = false
    var error: HistoryError?

    init(repository: FeatsRepositoryProtocol) {
        self.repository = repository
    }

    func loadHistory() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch all completions
            let completions = await repository.getFeatCompletions()

            // Group completions by featId
            let groupedCompletions = Dictionary(grouping: completions, by: { $0.featId })

            // Fetch monthly feats to get feat details
            let monthlyFeats = try await repository.getMonthlyFeats()

            // Build FeatHistory objects
            var histories: [FeatHistory] = []

            for (featId, attempts) in groupedCompletions {
                // Find the feat details
                if let feat = monthlyFeats.feats.first(where: { $0.id.rawValue == featId }) {
                    let bestScore = await repository.getUserBestScore(for: feat.id)

                    let history = FeatHistory(
                        id: featId,
                        featName: feat.name,
                        movement: feat.movement,
                        imageURLString: feat.imageURL.absoluteString,
                        attempts: attempts.sorted { $0.completedAt > $1.completedAt },
                        personalRecord: bestScore
                    )
                    histories.append(history)
                }
            }

            // Sort by most recent attempt
            featHistories = histories.sorted { lhs, rhs in
                guard let lhsDate = lhs.attempts.first?.completedAt,
                      let rhsDate = rhs.attempts.first?.completedAt else {
                    return false
                }
                return lhsDate > rhsDate
            }
        } catch {
            self.error = .loadFailed(error)
        }
    }

    func refreshHistory() async {
        await loadHistory()
    }
}

enum HistoryError: LocalizedError {
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Unable to load history. Pull to refresh."
        }
    }
}
