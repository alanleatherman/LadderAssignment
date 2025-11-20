//
//  CircularTimerView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct CircularTimerView: View {
    let elapsedTime: TimeInterval
    let totalTime: TimeInterval

    private var progress: Double {
        min(elapsedTime / totalTime, 1.0)
    }

    private var remainingTime: TimeInterval {
        max(totalTime - elapsedTime, 0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            VStack(spacing: 4) {
                Text(timeString(from: remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
    }

    private var progressColor: Color {
        if progress < 0.5 {
            return .green
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
