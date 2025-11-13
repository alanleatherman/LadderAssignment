//
//  RepCounterView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct RepCounterView: View {
    let count: Int
    let physics: RepCounterPhysics
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    @State private var lastUpdateTime = Date()
    @State private var physicsTimer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            Text("REPS")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Physics-based animated counter
            Text("\(physics.currentDisplayValue)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .onAppear {
                    startPhysicsUpdate()
                }
                .onDisappear {
                    physicsTimer?.invalidate()
                    physicsTimer = nil
                }
                .onChange(of: count) { oldValue, newValue in
                    physics.setTarget(newValue)
                }

            // Increment/Decrement buttons
            HStack(spacing: 40) {
                Button {
                    onDecrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                }
                .disabled(count == 0)
                .opacity(count == 0 ? 0.3 : 1.0)

                Button {
                    onIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func startPhysicsUpdate() {
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            let now = Date()
            let deltaTime = now.timeIntervalSince(lastUpdateTime)
            lastUpdateTime = now

            physics.tick(deltaTime: deltaTime)
        }
    }
}
