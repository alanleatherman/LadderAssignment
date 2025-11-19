//
//  RepCounterPhysics.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

@Observable
final class RepCounterPhysics {
    private(set) var displayValue: Double = 0
    private var velocity: Double = 0
    private var targetValue: Double = 0

    private let springStiffness: Double = 300
    private let springDamping: Double = 20

    func setTarget(_ value: Int) {
        let delta = Double(value) - targetValue
        targetValue = Double(value)

        // Add initial velocity based on change
        velocity += delta * 10
    }

    func tick(deltaTime: Double) {
        let displacement = targetValue - displayValue
        let springForce = displacement * springStiffness
        let dampingForce = -velocity * springDamping

        velocity += (springForce + dampingForce) * deltaTime
        displayValue += velocity * deltaTime

        // Snap to target when close enough
        if abs(displacement) < 0.01 && abs(velocity) < 0.1 {
            displayValue = targetValue
            velocity = 0
        }
    }

    var currentDisplayValue: Int {
        Int(displayValue.rounded())
    }
}
