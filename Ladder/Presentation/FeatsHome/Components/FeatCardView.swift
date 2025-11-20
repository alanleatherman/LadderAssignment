//
//  FeatCardView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite
import AVKit

struct FeatCardView: View {
    let feat: Feat
    let isFeatured: Bool
    let userBestScore: UserBestScore?
    @Binding var selectedFeat: Feat?

    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?
    @State private var isVideoLoading = true

    var body: some View {
        Button {
            selectedFeat = feat
        } label: {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    backgroundMedia(geometry: geometry)
                    gradientOverlays
                    contentOverlay(geometry: geometry)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Subviews

    @ViewBuilder
    private func backgroundMedia(geometry: GeometryProxy) -> some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .onAppear {
                        player.play()
                    }
                    .overlay {
                        if isVideoLoading {
                            Color.gray.opacity(0.3)
                                .shimmer()
                                .transition(.opacity)
                        }
                    }
            } else {
                AsyncImage(url: feat.imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.3))) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.2)
                            .overlay(
                                ProgressView()
                                    .tint(.white.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .transition(.opacity)
                    case .failure:
                        Color.gray.opacity(0.2)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .onAppear {
                    setupPlayer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            cleanupPlayer()
        }
    }

    private var gradientOverlays: some View {
        ZStack {
            // Color tint overlay
            LinearGradient(
                colors: [
                    Color.ladderPrimary.opacity(0.3),
                    .clear,
                    .black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Bottom gradient for text readability - extends all the way down
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
            }
        }
    }

    @ViewBuilder
    private func contentOverlay(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            topBadges(geometry: geometry)
            Spacer()
            featInfo
            bottomInfo
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 58, 88))
    }

    @ViewBuilder
    private func topBadges(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top) {
            if isFeatured {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.black)
                    Text("Challenge of the Month")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.ladderPrimary)
                .clipShape(Capsule())
            }

            Spacer()

            if let userBest = userBestScore {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.ladderPrimary)
                        Text("\(userBest.repCount) PR")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())

                    Text("Tap to beat your record")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.top, max(geometry.safeAreaInsets.top, 50) + 67)
    }

    private var featInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feat.name.uppercased())
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(feat.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
        }
    }

    private var bottomInfo: some View {
        HStack {
            userAvatars

            Text("\(feat.completionCount) Completions")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white)
        }
    }

    private var userAvatars: some View {
        HStack(spacing: -8) {
            ForEach(feat.top3Users.prefix(3), id: \.id) { user in
                AsyncImage(url: user.imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.3))) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func setupPlayer() {
        isVideoLoading = true
        let newPlayer = AVPlayer(url: feat.videoURL)
        newPlayer.isMuted = true

        player = newPlayer

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        Task { @MainActor in
            while newPlayer.currentItem?.status != .readyToPlay {
                try? await Task.sleep(for: .milliseconds(50))
            }

            try? await Task.sleep(for: .milliseconds(100))
            withAnimation {
                self.isVideoLoading = false
            }
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
