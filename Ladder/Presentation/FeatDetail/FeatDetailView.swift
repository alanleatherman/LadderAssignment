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

    private var interactor: FeatsInteractor {
        container.interactors.feats
    }

    private var userBestScore: UserBestScore? {
        interactor.getUserBest(for: feat.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Group {
                        if let player = player {
                            VideoPlayer(player: player)
                                .frame(height: 300)
                                .onAppear {
                                    // Start playing automatically and loop
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

                    VStack(alignment: .leading, spacing: 16) {
                            // Title and description
                            Text(feat.name.uppercased())
                                .font(.title.bold())

                            Text(feat.description)
                                .font(.body)
                                .foregroundStyle(.secondary)

                            // Your Best Score (if completed)
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

                            // Stats
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

                            Divider()

                            // Top 3 leaders preview
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Performers")
                                    .font(.headline)

                                HStack(spacing: 16) {
                                    ForEach(feat.top3Users, id: \.id) { user in
                                        VStack {
                                            AsyncImage(url: user.imageURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.3))
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure:
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.4))
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .font(.title2)
                                                                .foregroundStyle(.white.opacity(0.6))
                                                        )
                                                @unknown default:
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.3))
                                                }
                                            }
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.yellow, lineWidth: 3)
                                            )
                                        }
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

                            Divider()

                            // Instructions
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
                        .padding()
                    }
                }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .safeAreaInset(edge: .bottom) {
                Button {
                    container.interactors.featTest.configure(with: feat)
                    showFeatTest = true
                } label: {
                    if userBestScore != nil {
                        Text("TRY TO BEAT YOUR SCORE")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ladderPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("START TEST")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ladderPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
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

        // Auto-play
        newPlayer.play()
    }

    private func cleanupPlayer() {
        // Remove observer properly
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
