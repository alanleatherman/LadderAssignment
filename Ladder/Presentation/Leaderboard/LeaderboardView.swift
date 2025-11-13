//
//  LeaderboardView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite

struct LeaderboardView: View {
    @Environment(\.container) private var container
    let feat: Feat

    private var interactor: LeaderboardInteractor {
        container.interactors.leaderboard
    }

    var body: some View {
        VStack(spacing: 0) {
            // Time filter
            TimeFilterView(
                selectedFilter: interactor.timeFilter,
                onFilterChange: { filter in
                    interactor.updateTimeFilter(filter)
                }
            )
            .padding()

            if interactor.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let error = interactor.error {
                errorView(error)
            } else if let leaderboard = interactor.leaderboard {
                leaderboardContent(leaderboard)
            }
        }
        .navigationTitle(feat.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await interactor.loadLeaderboard(for: feat.id)
        }
        .refreshable {
            await interactor.refreshLeaderboard(for: feat.id)
        }
    }

    @ViewBuilder
    private func leaderboardContent(_ leaderboard: FeatLeaderboard) -> some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                // Header
                leaderboardHeader

                // Placements
                ForEach(Array(leaderboard.placements.enumerated()), id: \.element.id) { index, placement in
                    LeaderboardRowView(
                        placement: placement,
                        isCurrentUser: placement.name == "You" // In real app, check against user ID
                    )
                    .id(placement.id)
                }
            }
        }
    }

    private var leaderboardHeader: some View {
        HStack {
            Text("Ranking")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text("Total Reps")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func errorView(_ error: LeaderboardError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await interactor.loadLeaderboard(for: feat.id)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
}
