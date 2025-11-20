//
//  LeaderboardInteractor.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import Dependencies
import Creed_Lite
import Observation

@MainActor
protocol LeaderboardInteractorProtocol: AnyObject {
    var leaderboard: FeatLeaderboard? { get set }
    var isLoading: Bool { get set }
    var error: LeaderboardError? { get set }
    var timeFilter: TimeFilter { get set }

    func loadLeaderboard(for featId: Feat.Id) async
    func refreshLeaderboard(for featId: Feat.Id) async
    func updateTimeFilter(_ filter: TimeFilter)
}

@MainActor
@Observable
final class LeaderboardInteractor: LeaderboardInteractorProtocol {
    @ObservationIgnored
    @Dependency(\.featsClient) private var featsClient
    
    var leaderboard: FeatLeaderboard?
    var isLoading: Bool = false
    var error: LeaderboardError?
    var timeFilter: TimeFilter = .thisWeek
    
    func loadLeaderboard(for featId: Feat.Id) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            leaderboard = try await featsClient.getFeatLeaderboard(featId)
        } catch {
            self.error = .loadFailed(error)
        }
    }
    
    func refreshLeaderboard(for featId: Feat.Id) async {
        await loadLeaderboard(for: featId)
    }
    
    func updateTimeFilter(_ filter: TimeFilter) {
        timeFilter = filter
        // In real implementation, this would trigger a new load
        // For now, just filter the existing data
    }
}

enum LeaderboardError: LocalizedError {
    case loadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Unable to load leaderboard. Pull to refresh."
        }
    }
}

enum TimeFilter: String, CaseIterable {
    case thisWeek = "This Week"
    case allTime = "All Time"
}
