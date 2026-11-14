//
//  PracticeSessionController.swift
//  Akorio
//

import Foundation
import Observation
import SwiftData

struct PracticeSessionSummary: Hashable {
    let durationSeconds: Int
    let chordTransitionCount: Int
    let bpm: Int
    let beatsPerChord: Int
    let chordLabels: [String]
    let targetDurationMinutes: Int?
    let goalCompleted: Bool
}

/// Runs one practice session: play, pause, finish, the exit confirmation,
/// the summary and the history record. What to practise comes from
/// `planProvider`, so the chord picker and options stay with `AppViewModel`.
@Observable
final class PracticeSessionController {
    struct Plan {
        var chordLabels: [String] = []
        var configuration = PracticeConfiguration.standard
    }

    /// The real-time engine (timer, count-in, click sounds) — see MetronomeEngine.swift.
    let metronome = MetronomeEngine()

    var currentSummary: PracticeSessionSummary?
    var isPaused = false
    var isPresented = false
    var showExitAlert = false
    var shouldRequestReview = false

    @ObservationIgnored var planProvider: () -> Plan = { Plan() }
    /// Called just before the practice screen closes, so the plan can be remembered.
    @ObservationIgnored var willClose: (() -> Void)?

    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var settingsRecord: AppSettings?

    init() {
        metronome.goalReachedHandler = { [weak self] in
            self?.finish(goalReached: true)
        }
    }

    func attach(context: ModelContext, settings: AppSettings) {
        self.context = context
        self.settingsRecord = settings
    }

    // MARK: - Live state
    var isPlaying: Bool { metronome.isPlaying }
    var isCountingIn: Bool { metronome.isCountingIn }
    var countInBeatsLeft: Int { metronome.countInBeatsLeft }
    var currentChordLabel: String { metronome.currentChordLabel }
    var nextChordLabel: String { metronome.nextChordLabel }
    var beatInCurrentChord: Int { metronome.beatInCurrentChord }
    var elapsedSeconds: Int { metronome.elapsedPracticeSeconds }
    var remainingSeconds: Int? {
        PracticeGoalCalculator.remainingSeconds(
            elapsedSeconds: metronome.elapsedPracticeSeconds,
            goal: planProvider().configuration.durationGoal
        )
    }

    // MARK: - Lifecycle
    /// Stops everything and clears the session state.
    func reset() {
        metronome.stop()
        isPaused = false
        currentSummary = nil
        showExitAlert = false
    }

    /// Opens the practice screen with a clean session.
    func start() {
        reset()
        isPresented = true
    }

    func togglePlay() {
        if metronome.isPlaying {
            pause()
        } else {
            currentSummary = nil
            isPaused = false
            metronome.toggle()
        }
    }

    func pause() {
        if metronome.isCountingIn && !metronome.hasStartedPractice {
            metronome.stop()
            isPaused = false
            return
        }
        metronome.pause()
        isPaused = true
    }

    func resume() {
        metronome.resume()
        isPaused = false
    }

    func repeatSession() {
        currentSummary = nil
        isPaused = false
    }

    func finish(goalReached: Bool = false) {
        let plan = planProvider()
        let goal = plan.configuration.durationGoal
        let elapsedSeconds = metronome.elapsedPracticeSeconds
        let durationSeconds = PracticeGoalCalculator.recordedDurationSeconds(
            elapsedSeconds: elapsedSeconds,
            goal: goal,
            goalReached: goalReached
        )
        let transitionCount = metronome.chordTransitionCount

        metronome.stop()
        isPaused = false

        guard durationSeconds > 0 else { return }

        let summary = PracticeSessionSummary(
            durationSeconds: durationSeconds,
            chordTransitionCount: transitionCount,
            bpm: plan.configuration.bpm,
            beatsPerChord: plan.configuration.beatsPerChord,
            chordLabels: plan.chordLabels,
            targetDurationMinutes: goal.minutes,
            goalCompleted: goalReached || PracticeGoalCalculator.isCompleted(
                elapsedSeconds: elapsedSeconds,
                goal: goal
            )
        )

        record(summary)
        currentSummary = summary
    }

    private func record(_ summary: PracticeSessionSummary) {
        guard let context else { return }
        context.insert(PracticeSession(
            durationSeconds: summary.durationSeconds,
            chordTransitionCount: summary.chordTransitionCount,
            bpm: summary.bpm,
            beatsPerChord: summary.beatsPerChord,
            chordLabels: summary.chordLabels,
            targetDurationMinutes: summary.targetDurationMinutes,
            goalCompleted: summary.goalCompleted
        ))
        try? context.save()
    }

    // MARK: - Leaving the practice screen
    func requestExit() {
        let shouldConfirm = metronome.isPlaying || isPaused || metronome.hasStartedPractice
        guard shouldConfirm else {
            closeFlow()
            return
        }

        if metronome.isPlaying {
            metronome.pause()
        }
        isPaused = metronome.hasStartedPractice
        showExitAlert = true
    }

    func cancelExit() {
        showExitAlert = false
    }

    func confirmExit() {
        closeFlow()
    }

    private func closeFlow() {
        metronome.stop()
        willClose?()
        reset()
        isPresented = false
    }

    /// Ends the summary screen and lets the review prompt follow when eligible.
    func finishSummary() {
        reset()
        isPresented = false
    }

    // MARK: - App Store review
    func requestReviewIfEligible() {
        guard let context, let settingsRecord else { return }
        guard let completedCount = try? context.fetchCount(FetchDescriptor<PracticeSession>()) else {
            return
        }
        guard ReviewRequestPolicy.isEligible(
            completedSessionCount: completedCount,
            hasRequestedReview: settingsRecord.hasRequestedAppStoreReview
        ) else {
            return
        }
        shouldRequestReview = true
    }

    func reviewRequestWasHandled() {
        shouldRequestReview = false
        settingsRecord?.hasRequestedAppStoreReview = true
        try? context?.save()
    }
}
