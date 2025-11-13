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

        case .challengeStarted:
            selection.selectionChanged()

        case .buttonTap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
