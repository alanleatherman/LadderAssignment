//
//  BreathingGuide.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct BreathingGuide: View {
    @State private var scale: CGFloat = 1.0
    @State private var breatheIn = true
    @State private var timer: Timer?
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)

                Image(systemName: "wind")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Text(breatheIn ? "Breathe In" : "Breathe Out")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            startBreathingAnimation()
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }

    private func startBreathingAnimation() {
        scale = 1.0
        breatheIn = true

        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            scale = 1.5
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            breatheIn.toggle()
        }
    }

    private func stopBreathingAnimation() {
        timer?.invalidate()
        timer = nil
        animationTask?.cancel()
        animationTask = nil
    }
}
