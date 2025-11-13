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
    @Dependency(\.featsClient) private var featsClient
    
    var monthlyFeats: MonthlyFeats?
    var selectedFeat: Feat?
    var isLoading: Bool = false
    var error: FeatsError?
    
    func loadMonthlyFeats() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            monthlyFeats = try await featsClient.listMonthlyFeats()
        } catch {
            self.error = .loadFailed(error)
        }
    }
    
    func selectFeat(_ feat: Feat) {
        selectedFeat = feat
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
