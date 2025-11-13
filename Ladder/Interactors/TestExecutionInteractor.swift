//
//  TestExecutionInteractor.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import Observation
import Creed_Lite

@MainActor
@Observable
final class TestExecutionInteractor {

    var repCount: Int = 0
    var isActive: Bool = false
    var startTime: Date?
    var elapsedTime: TimeInterval = 0
    var phase: TestPhase = .ready

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    
    var feat: Feat?
    let testDuration: TimeInterval = 300 // 5 minutes
    
    enum TestPhase: Equatable {
        case ready
        case countdown(Int)
        case active
        case paused
        case complete(repCount: Int)
    }
    
    func configure(with feat: Feat) {
        self.feat = feat
        reset()
    }
    
    func startCountdown(duration: Int = 3) {
        phase = .countdown(duration)
        
        countdownTask?.cancel()
        countdownTask = Task {
            for i in stride(from: duration, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                phase = .countdown(i)
                try? await Task.sleep(for: .seconds(1))
            }
            
            guard !Task.isCancelled else { return }
            startTest()
        }
    }
    
    func startTest() {
        phase = .active
        isActive = true
        startTime = Date()
        repCount = 0
        
        startTimer()
    }
    
    func incrementRep() {
        guard isActive else { return }
        repCount += 1
        
        // Check for milestones
        if repCount % 10 == 0 {
            // Trigger milestone celebration
            NotificationCenter.default.post(
                name: .repMilestone,
                object: nil,
                userInfo: ["count": repCount]
            )
        }
    }
    
    func decrementRep() {
        guard isActive, repCount > 0 else { return }
        repCount -= 1
    }
    
    func pauseTest() {
        phase = .paused
        isActive = false
        timerTask?.cancel()
    }
    
    func resumeTest() {
        phase = .active
        isActive = true
        startTimer()
    }
    
    func completeTest() {
        phase = .complete(repCount: repCount)
        isActive = false
        timerTask?.cancel()
        
        // In real implementation, submit to server via FeatsClient
        // For now, just complete locally
    }
    
    func reset() {
        timerTask?.cancel()
        countdownTask?.cancel()
        
        repCount = 0
        isActive = false
        startTime = nil
        elapsedTime = 0
        phase = .ready
    }
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            guard let startTime = self.startTime else { return }
            
            while !Task.isCancelled && isActive {
                elapsedTime = Date().timeIntervalSince(startTime)
                
                // Check if test duration completed
                if elapsedTime >= testDuration {
                    completeTest()
                    break
                }
                
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    deinit {
        timerTask?.cancel()
        countdownTask?.cancel()
    }
}

extension Notification.Name {
    static let repMilestone = Notification.Name("repMilestone")
}
