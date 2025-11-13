//
//  FeatCardView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite

struct FeatCardView: View {
    let feat: Feat
    let isFeatured: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
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
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

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
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Bottom gradient for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
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

                    Text(feat.name.uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(feat.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)

                    HStack {
                        // Top 3 users
                        HStack(spacing: -8) {
                            ForEach(feat.top3Users.prefix(3), id: \.id) { user in
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
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            }
                        }

                        Text("\(feat.completionCount) Completions")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
