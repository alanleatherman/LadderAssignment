//
//  HistoryView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/19/25.
//

import SwiftUI
import Creed_Lite

struct HistoryView: View {
    @Environment(\.container) private var container
    @Environment(\.appState) private var appState

    private var interactor: HistoryInteractorProtocol {
        container.interactors.history
    }

    private var leaderboardInteractor: LeaderboardInteractorProtocol {
        container.interactors.leaderboard
    }

    var body: some View {
        NavigationStack {
            Group {
                if interactor.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let error = interactor.error {
                    errorView(error)
                } else if interactor.featHistories.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("History & PRs")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await interactor.loadHistory()
            }
            .refreshable {
                await interactor.refreshHistory()
            }
            .onChange(of: appState.completionTimestamp) { _, _ in
                Task {
                    await interactor.loadHistory()
                }
            }
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(interactor.featHistories) { featHistory in
                    FeatHistoryCard(
                        featHistory: featHistory,
                        leaderboardInteractor: leaderboardInteractor
                    )
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No History Yet")
                .font(.title2.bold())

            Text("Complete your first challenge to start tracking your progress!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(_ error: HistoryError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await interactor.loadHistory()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
}

struct FeatHistoryCard: View {
    let featHistory: FeatHistory
    let leaderboardInteractor: LeaderboardInteractorProtocol

    @State private var isExpanded = false
    @State private var userRank: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Header with feat info and PR
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: featHistory.imageURLString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty, .failure:
                            Color.gray.opacity(0.2)
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(featHistory.featName)
                            .font(.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            if let pr = featHistory.personalRecord {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption2)
                                    Text("PR: \(pr.repCount)")
                                        .font(.subheadline.bold())
                                }
                                .foregroundStyle(Color.ladderPrimary)
                            }

                            Text("\(featHistory.totalAttempts) attempts")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.ladderPrimary)
                }
                .padding()
            }

            // Expanded content
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()

                    // Stats row
                    HStack(spacing: 20) {
                        StatItem(
                            title: "Personal Record",
                            value: "\(featHistory.personalRecord?.repCount ?? 0)",
                            icon: "trophy.fill",
                            color: Color.ladderPrimary
                        )

                        StatItem(
                            title: "Total Attempts",
                            value: "\(featHistory.totalAttempts)",
                            icon: "figure.run",
                            color: .blue
                        )

                        StatItem(
                            title: "Average Reps",
                            value: "\(featHistory.averageReps)",
                            icon: "chart.bar.fill",
                            color: .green
                        )

                        if let rank = userRank {
                            StatItem(
                                title: "Rank",
                                value: "#\(rank)",
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Attempts list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Attempts")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ForEach(featHistory.attempts.prefix(5), id: \.id) { attempt in
                            AttemptRow(attempt: attempt)
                        }

                        if featHistory.attempts.count > 5 {
                            Text("+ \(featHistory.attempts.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            // Load leaderboard to get user's rank
            // The featHistory.id is the featId string
            let featId = Feat.Id(rawValue: featHistory.id)
            await leaderboardInteractor.loadLeaderboard(for: featId)
            if let leaderboard = leaderboardInteractor.leaderboard,
               let pr = featHistory.personalRecord {
                let betterThanUser = leaderboard.placements.filter { $0.totalRepCount > pr.repCount }
                userRank = betterThanUser.count + 1
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AttemptRow: View {
    let attempt: FeatCompletion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(attempt.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)

                Text(attempt.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(attempt.repCount)")
                .font(.title3.bold())
                .foregroundStyle(Color.ladderPrimary)

            Text("reps")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - Previews

#Preview("History View - Empty") {
    HistoryView()
        .inject(.preview)
        .preferredColorScheme(.dark)
}

#Preview("Attempt Row") {
    let attempt = FeatCompletion(
        featId: "test-feat",
        completedAt: Date(),
        repCount: 42,
        duration: 300
    )

    AttemptRow(attempt: attempt)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
