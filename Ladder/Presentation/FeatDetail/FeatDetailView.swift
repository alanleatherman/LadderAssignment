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
    @Environment(\.dismiss) private var dismiss

    @State private var showTestExecution = false
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    let feat: Feat

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
                                    value: "5 min",
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
                                            AsyncImage(url: user.imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .transition(.opacity)
                                                } else {
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
                                        text: "You have 5 minutes to complete as many air squats as possible"
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
                    container.interactors.testExecution.configure(with: feat)
                    showTestExecution = true
                } label: {
                    Text("START TEST")
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
            .fullScreenCover(isPresented: $showTestExecution) {
                TestExecutionView()
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
