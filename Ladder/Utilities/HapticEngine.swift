//
//  HapticEngine.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import UIKit

final class HapticEngine {
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    enum HapticEvent {
        case repCounted
        case milestone(Int)
        case testComplete
        case prBeaten
        case challengeStarted
        case buttonTap
    }

    func prepare() {
        impact.prepare()
        notification.prepare()
        selection.prepare()
    }

    func trigger(_ event: HapticEvent) {
        switch event {
        case .repCounted:
            impact.impactOccurred(intensity: 0.7)

        case .milestone(_):
            notification.notificationOccurred(.success)

            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }

        case .testComplete:
            notification.notificationOccurred(.success)

        case .prBeaten:
            Task {
                await notification.notificationOccurred(.success)

                try? await Task.sleep(for: .milliseconds(80))
                await UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)

                try? await Task.sleep(for: .milliseconds(80))
                await UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)

                try? await Task.sleep(for: .milliseconds(120))
                await UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)

                try? await Task.sleep(for: .milliseconds(80))
                await UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            }

        case .challengeStarted:
            selection.selectionChanged()

        case .buttonTap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
