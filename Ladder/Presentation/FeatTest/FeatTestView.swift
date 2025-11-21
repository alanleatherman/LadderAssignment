//
//  FeatTestView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct FeatTestView: View {
    @Environment(\.container) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false
    @State private var previousBest: Int?

    private var interactor: FeatTestInteractorProtocol {
        container.interactors.featTest
    }

    private var leaderboardInteractor: LeaderboardInteractorProtocol {
        container.interactors.leaderboard
    }

    private var featsInteractor: FeatsInteractorProtocol {
        container.interactors.feats
    }

    private var hapticEngine: HapticEngine {
        container.hapticEngine
    }

    private var repCounterAnimator: RepCounterAnimator {
        container.repCounterAnimator
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundForPhase
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    Group {
                        switch interactor.phase {
                        case .ready:
                            readyView
                        case .countdown(let count):
                            countdownView(count: count)
                        case .go:
                            goView
                        case .active:
                            activeTestView
                        case .paused:
                            pausedView
                        case .complete(let repCount):
                            completeView(repCount: repCount)
                        }
                    }
                    .animation(.easeInOut(duration: 0.5), value: interactor.phase)

                    Spacer()

                    controlsView
                        .padding(.bottom, 40)
                }

                if showConfetti {
                    ConfettiView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .onAppear {
                hapticEngine.prepare()
                repCounterAnimator.reset()
                if let feat = interactor.feat {
                    previousBest = featsInteractor.getUserBest(for: feat.id)?.repCount
                }
            }
        }
    }

    // MARK: - Phase Views

    private var readyView: some View {
        VStack(spacing: 24) {
            if let feat = interactor.feat {
                Text(feat.name.uppercased())
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("You'll have \(feat.durationText) to complete as many reps as possible")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Ready to start?")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func countdownView(count: Int) -> some View {
        VStack(spacing: 24) {
            Text("\(count)")
                .font(.system(size: 120, weight: .bold))
                .contentTransition(.numericText())

            Text("Get Ready!")
                .font(.title2)
                .foregroundStyle(.secondary)

            BreathingGuide()
        }
    }

    private var goView: some View {
        Text("GO!")
            .font(.system(size: 120, weight: .black))
            .foregroundStyle(Color.ladderPrimary)
            .transition(.scale.combined(with: .opacity))
    }

    private var activeTestView: some View {
        VStack(spacing: 32) {
            if let feat = interactor.feat {
                Text(feat.movement.uppercased())
                    .font(.title.bold())
                    .foregroundStyle(.primary)
            }

            CircularTimerView(
                elapsedTime: interactor.elapsedTime,
                totalTime: interactor.testDuration
            )

            RepCounterView(
                count: interactor.repCount,
                animator: container.repCounterAnimator,
                onIncrement: {
                    interactor.incrementRep()
                    hapticEngine.trigger(.repCounted)
                },
                onDecrement: {
                    interactor.decrementRep()
                }
            )
        }
    }

    private var pausedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Paused")
                .font(.title.bold())

            Text("Reps: \(interactor.repCount)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(timeString(from: interactor.elapsedTime))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func completeView(repCount: Int) -> some View {
        let userRank = calculateUserRank(for: repCount)

        return VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ladderPrimary, Color.ladderPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.ladderPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                VStack(spacing: 4) {
                    Text("\(repCount)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(.black)

                    Text("REPS")
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.7))
                }
            }

            VStack(spacing: 12) {
                let isNewPR = if let prev = previousBest {
                    repCount > prev
                } else {
                    repCount > 0
                }

                if isNewPR {
                    Text("NEW PR! 🎉")
                        .font(.title.bold())
                        .foregroundStyle(Color.ladderPrimary)

                    if let prev = previousBest {
                        Text("Previous PR: \(prev) reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Your first completion!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Test Complete!")
                        .font(.title.bold())
                }

                if let rank = userRank {
                    HStack(spacing: 4) {
                        Text("You're ranked")
                        Text("#\(rank)")
                            .fontWeight(.black)
                            .foregroundStyle(Color.ladderPrimary)
                    }
                    .font(.title3)
                }

                Text(motivationalMessage(for: repCount))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let feat = interactor.feat {
                    Text("Keep training to climb the \(feat.name) leaderboard!")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            let isNewPR = if let prev = previousBest {
                repCount > prev
            } else {
                repCount > 0
            }

            if isNewPR {
                hapticEngine.trigger(.prBeaten)
                withAnimation {
                    showConfetti = true
                }

                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation {
                        showConfetti = false
                    }
                }
            } else {
                hapticEngine.trigger(.testComplete)
            }

            if let feat = interactor.feat {
                Task {
                    await leaderboardInteractor.loadLeaderboard(for: feat.id)
                }
            }
        }
    }

    private func motivationalMessage(for reps: Int) -> String {
        switch reps {
        case 0..<10:
            return "Every journey starts with a first step!"
        case 10..<25:
            return "Solid effort! Keep building!"
        case 25..<50:
            return "Great work! You're getting stronger!"
        case 50..<75:
            return "Impressive! Keep pushing!"
        case 75..<100:
            return "Outstanding performance!"
        default:
            return "Absolutely crushing it! 🔥"
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlsView: some View {
        switch interactor.phase {
        case .ready:
            Button {
                hapticEngine.trigger(.challengeStarted)
                interactor.startCountdown()
            } label: {
                Text("START")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ladderPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

        case .countdown:
            EmptyView()

        case .go:
            EmptyView()

        case .active:
            Button {
                interactor.completeTest()
                hapticEngine.trigger(.buttonTap)
            } label: {
                Label("Finish", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ladderPrimary)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

        case .paused:
            HStack(spacing: 16) {
                Button {
                    interactor.resumeTest()
                    hapticEngine.trigger(.buttonTap)
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ladderPrimary)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    interactor.completeTest()
                    hapticEngine.trigger(.buttonTap)
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ladderPrimary)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)

        case .complete:
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ladderPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private var backgroundForPhase: Color {
        switch interactor.phase {
        case .ready:
            return Color(uiColor: .systemBackground)
        case .countdown:
            return Color.orange.opacity(0.1)
        case .go:
            return Color.ladderPrimary.opacity(0.15)
        case .active:
            return Color.blue.opacity(0.05)
        case .paused:
            return Color.orange.opacity(0.1)
        case .complete:
            return Color.green.opacity(0.1)
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func calculateUserRank(for repCount: Int) -> Int? {
        guard let leaderboard = leaderboardInteractor.leaderboard else {
            return nil
        }

        let betterThanUser = leaderboard.placements.filter { $0.totalRepCount > repCount }
        let rank = betterThanUser.count + 1
        return rank
    }
}

// MARK: - Previews

#Preview("Feat Test - Ready") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .ready
        }
}

#Preview("Feat Test - Countdown") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .countdown(2)
        }
}

#Preview("Feat Test - Go") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .go
        }
}

#Preview("Feat Test - Active") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .active
            AppContainer.preview.interactors.featTest.repCount = 25
            AppContainer.preview.interactors.featTest.elapsedTime = 150
        }
}

#Preview("Feat Test - Paused") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .paused
            AppContainer.preview.interactors.featTest.repCount = 30
            AppContainer.preview.interactors.featTest.elapsedTime = 180
        }
}

#Preview("Feat Test - Complete") {
    FeatTestView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.featTest.phase = .complete(repCount: 50)
        }
}
