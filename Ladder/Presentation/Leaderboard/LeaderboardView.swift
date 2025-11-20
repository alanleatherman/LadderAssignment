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
    @Environment(\.appState) private var appState
    let feat: Feat

    private var interactor: LeaderboardInteractorProtocol {
        container.interactors.leaderboard
    }

    private var featsInteractor: FeatsInteractorProtocol {
        container.interactors.feats
    }

    private var userBestScore: UserBestScore? {
        featsInteractor.getUserBest(for: feat.id)
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
            await featsInteractor.loadUserData()
        }
        .refreshable {
            await interactor.refreshLeaderboard(for: feat.id)
            await featsInteractor.loadUserData()
        }
        .onChange(of: appState.completionTimestamp) { _, _ in
            Task {
                await featsInteractor.loadUserData()
            }
        }
    }

    @ViewBuilder
    private func leaderboardContent(_ leaderboard: FeatLeaderboard) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // User's position card (if they have completed the feat)
                if let userBest = userBestScore {
                    userPositionCard(userBest: userBest, leaderboard: leaderboard)
                }

                VStack(spacing: 1) {
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

                    // Show user's position if not in top placements
                    if let userBest = userBestScore {
                        let userRank = leaderboard.placements.filter { $0.totalRepCount > userBest.repCount }.count + 1
                        let isUserInList = leaderboard.placements.contains { $0.name == "You" }

                        if !isUserInList && userRank > leaderboard.placements.count {
                            // Separator
                            HStack {
                                Text("...")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .systemGroupedBackground))

                            // User's row
                            userLeaderboardRow(rank: userRank, repCount: userBest.repCount)
                        }
                    }
                }
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private func userLeaderboardRow(rank: Int, repCount: Int) -> some View {
        HStack {
            // Rank movement indicator
            Color.clear
                .frame(width: 20)

            // Rank number
            Text("\(rank)")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 40, alignment: .leading)

            // User avatar placeholder
            Circle()
                .fill(Color.ladderPrimary.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("YOU")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.ladderPrimary)
                )

            // Name
            Text("You")
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            // Rep count
            Text("\(repCount)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.ladderPrimary.opacity(0.1))
    }

    @ViewBuilder
    private func userPositionCard(userBest: UserBestScore, leaderboard: FeatLeaderboard) -> some View {
        // Find user's rank - count how many have more reps than user
        let betterThanUser = leaderboard.placements.filter { $0.totalRepCount > userBest.repCount }
        let userRank = betterThanUser.count + 1
        let toBeat = betterThanUser.count

        VStack(spacing: 12) {
            Text("Your Position")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                VStack {
                    Text("#\(userRank)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ladderPrimary)

                    Text("RANK")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    Text("\(userBest.repCount)")
                        .font(.system(size: 32, weight: .black, design: .rounded))

                    Text("REPS")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 50)

                VStack {
                    if userRank <= 3 {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.ladderPrimary)
                        Text("TOP 3")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.ladderPrimary)
                    } else if userRank <= 10 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.orange)
                        Text("TOP 10")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    } else if toBeat > 0 {
                        Text("\(toBeat)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("TO BEAT")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.ladderPrimary)
                        Text("#1!")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.ladderPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ladderPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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
