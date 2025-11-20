//
//  LeaderboardRowView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite

struct LeaderboardRowView: View {
    let placement: FeatLeaderBoardPlacement
    let isCurrentUser: Bool
    let overrideRank: Int?

    init(placement: FeatLeaderBoardPlacement, isCurrentUser: Bool, overrideRank: Int? = nil) {
        self.placement = placement
        self.isCurrentUser = isCurrentUser
        self.overrideRank = overrideRank
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank with movement indicator
            HStack(spacing: 4) {
                movementIndicator

                Text("\(overrideRank ?? placement.placement)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(isCurrentUser ? .green : .primary)
                    .frame(width: 40, alignment: .trailing)
            }

            // Avatar
            AsyncImage(url: placement.imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.3))) { phase in
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
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.6))
                        )
                @unknown default:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        isCurrentUser ? Color.green : Color.clear,
                        lineWidth: 3
                    )
            )

            // Name
            Text(placement.name)
                .font(.body.weight(isCurrentUser ? .bold : .regular))
                .foregroundStyle(isCurrentUser ? .green : .primary)

            Spacer()

            // Rep count
            Text("\(placement.totalRepCount)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            isCurrentUser ?
                Color.green.opacity(0.1) : Color(uiColor: .systemBackground)
        )
    }

    @ViewBuilder
    private var movementIndicator: some View {
        switch placement.movement {
        case .up:
            Image(systemName: "arrowtriangle.up.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .neutral:
            Image(systemName: "minus")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
