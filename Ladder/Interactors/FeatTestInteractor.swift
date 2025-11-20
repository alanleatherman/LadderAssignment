//
//  FeatTestInteractor.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation
import Observation
import Creed_Lite

enum TestPhase: Equatable {
    case ready
    case countdown(Int)
    case active
    case paused
    case complete(repCount: Int)
}

@MainActor
protocol FeatTestInteractorProtocol: AnyObject {
    var repCount: Int { get set }
    var isActive: Bool { get set }
    var startTime: Date? { get set }
    var elapsedTime: TimeInterval { get set }
    var phase: TestPhase { get set }
    var pausedElapsedTime: TimeInterval { get set }
    var lastMilestone: Int? { get set }
    var feat: Feat? { get set }
    var testDuration: TimeInterval { get }

    func configure(with feat: Feat)
    func startCountdown(duration: Int)
    func startTest()
    func incrementRep()
    func decrementRep()
    func pauseTest()
    func resumeTest()
    func completeTest()
    func reset()
}

extension FeatTestInteractorProtocol {
    func startCountdown() {
        startCountdown(duration: 3)
    }
}

@MainActor
@Observable
final class FeatTestInteractor: FeatTestInteractorProtocol {

    var repCount: Int = 0
    var isActive: Bool = false
    var startTime: Date?
    var elapsedTime: TimeInterval = 0
    var phase: TestPhase = .ready
    var pausedElapsedTime: TimeInterval = 0
    var lastMilestone: Int? = nil

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    @ObservationIgnored private let repository: FeatsRepositoryProtocol
    @ObservationIgnored private let appState: AppState

    var feat: Feat?
    
    var testDuration: TimeInterval {
        // Extract duration from feat name, fallback to 5 minutes
        guard let feat = feat else { return 300 }
        let name = feat.name.uppercased()
        if let match = name.range(of: #"\d+"#, options: .regularExpression) {
            let numberString = String(name[match])
            if let minutes = Int(numberString) {
                return TimeInterval(minutes * 60)
            }
        }
        return 300 // Default 5 minutes
    }

    init(repository: FeatsRepositoryProtocol, appState: AppState) {
        self.repository = repository
        self.appState = appState
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
        pausedElapsedTime = 0
        elapsedTime = 0

        startTimer()
    }
    
    func incrementRep() {
        guard isActive else { return }
        repCount += 1

        // Check for milestones (every 10 reps)
        if repCount % 10 == 0 {
            lastMilestone = repCount
        }
    }
    
    func decrementRep() {
        guard isActive, repCount > 0 else { return }
        repCount -= 1
    }
    
    func pauseTest() {
        phase = .paused
        isActive = false
        pausedElapsedTime = elapsedTime
        timerTask?.cancel()
    }

    func resumeTest() {
        phase = .active
        isActive = true
        startTime = Date().addingTimeInterval(-pausedElapsedTime)
        startTimer()
    }
    
    func completeTest() {
        phase = .complete(repCount: repCount)
        isActive = false
        timerTask?.cancel()

        Task {
            guard let feat = feat else { return }
            try? await repository.saveFeatCompletion(
                featId: feat.id,
                repCount: repCount,
                duration: elapsedTime
            )

            appState.notifyFeatCompleted(featId: feat.id.rawValue)
        }
    }
    
    func reset() {
        timerTask?.cancel()
        countdownTask?.cancel()

        repCount = 0
        isActive = false
        startTime = nil
        elapsedTime = 0
        pausedElapsedTime = 0
        phase = .ready
        lastMilestone = nil
    }
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            guard let startTime = self.startTime else { return }
            
            while !Task.isCancelled && isActive {
                elapsedTime = Date().timeIntervalSince(startTime)
                
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
