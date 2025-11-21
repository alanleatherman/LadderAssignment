//
//  FeatDetailView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite
import AVKit

struct FeatDetailView: View {
    @Environment(\.container) private var container
    @Environment(\.appState) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var showFeatTest = false
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    let feat: Feat

    private var interactor: FeatsInteractorProtocol {
        container.interactors.feats
    }

    private var userBestScore: UserBestScore? {
        interactor.getUserBest(for: feat.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    videoPlayerSection
                    contentSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .safeAreaInset(edge: .bottom) {
                ctaButton
            }
            .fullScreenCover(isPresented: $showFeatTest) {
                FeatTestView()
            }
            .onChange(of: appState.completionTimestamp) { _, _ in
                Task {
                    await interactor.loadUserData()
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var videoPlayerSection: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .onAppear {
                        player.play()
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .frame(height: 300)
                    .onAppear {
                        setupPlayer()
                    }
            }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleSection
            userBestScoreCard
            statsRow
            Divider()
            topPerformersSection
            Divider()
            instructionsSection
        }
        .padding()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feat.name.uppercased())
                .font(.title.bold())

            Text(feat.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var userBestScoreCard: some View {
        if let userBest = userBestScore {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Best")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading) {
                        Text("\(userBest.repCount)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(Color.ladderPrimary)

                        Text("REPS")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(userBest.achievedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            LeaderboardView(feat: feat)
                        } label: {
                            HStack(spacing: 4) {
                                Text("See Ranking")
                                Image(systemName: "chevron.right")
                            }
                            .font(.caption.bold())
                        }
                    }
                }
                .padding()
                .background(Color.ladderPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 32) {
            StatView(
                title: "Movement",
                value: feat.movement,
                icon: "figure.strengthtraining.traditional"
            )

            StatView(
                title: "Completions",
                value: "\(feat.completionCount)",
                icon: "person.3.fill"
            )

            StatView(
                title: "Duration",
                value: feat.durationText,
                icon: "clock.fill"
            )
        }
    }

    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(feat.top3Users, id: \.id) { user in
                    topPerformerAvatar(user: user)
                }

                Spacer()

                NavigationLink {
                    LeaderboardView(feat: feat)
                } label: {
                    Text("View All")
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.right")
                }
            }
        }
    }

    @ViewBuilder
    private func topPerformerAvatar(user: FeatUser) -> some View {
        VStack {
            CachedAsyncImage(
                url: user.imageURL,
                size: .thumbnail
            ) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.yellow, lineWidth: 3)
            )
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How It Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    number: 1,
                    text: "You have \(feat.durationText) to complete as many \(feat.movement.lowercased()) as possible"
                )
                InstructionRow(
                    number: 2,
                    text: "Maintain proper form throughout the test"
                )
                InstructionRow(
                    number: 3,
                    text: "Compare your results with the community"
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Feats of Strength")
                .font(.headline)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ctaButton: some View {
        Button {
            container.interactors.featTest.configure(with: feat)
            showFeatTest = true
        } label: {
            Text(userBestScore != nil ? "TRY TO BEAT YOUR SCORE" : "START TEST")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ladderPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Helper Methods

    private func setupPlayer() {
        let newPlayer = AVPlayer(url: feat.videoURL)
        newPlayer.isMuted = true

        player = newPlayer

        // Setup looping - store the observer token
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        newPlayer.play()
    }

    private func cleanupPlayer() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }

        player?.pause()
        player = nil
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.ladderPrimary)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.2))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Stat View") {
    StatView(
        title: "Movement",
        value: "Push-ups",
        icon: "figure.strengthtraining.traditional"
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Instruction Row") {
    VStack(spacing: 12) {
        InstructionRow(
            number: 1,
            text: "You have 5 minutes to complete as many push-ups as possible"
        )
        InstructionRow(
            number: 2,
            text: "Maintain proper form throughout the test"
        )
        InstructionRow(
            number: 3,
            text: "Compare your results with the community"
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
