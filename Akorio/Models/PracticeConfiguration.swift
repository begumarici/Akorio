//
//  PracticeConfiguration.swift
//  Akorio
//

import Foundation

/// Every option that shapes a practice session, in one value. The live
/// session, saved chord sets, the "continue" card and the metronome all use
/// this type, so a new option is added here once instead of in each of them.
struct PracticeConfiguration: Equatable {
    static let bpmRange = 40...240
    static let beatsPerChordRange = 1...8
    static let standard = PracticeConfiguration()

    var bpm: Int {
        didSet { bpm = bpm.clamped(to: Self.bpmRange) }
    }
    var beatsPerChord: Int {
        didSet { beatsPerChord = beatsPerChord.clamped(to: Self.beatsPerChordRange) }
    }
    var preventBackToBackRepeat: Bool
    var countInEnabled: Bool
    var metronomeSoundEnabled: Bool
    var durationGoal: PracticeDurationGoal
    var accentFirstBeat: Bool

    init(
        bpm: Int = 80,
        beatsPerChord: Int = 4,
        preventBackToBackRepeat: Bool = true,
        countInEnabled: Bool = true,
        metronomeSoundEnabled: Bool = true,
        durationGoal: PracticeDurationGoal = .tenMinutes,
        accentFirstBeat: Bool = true
    ) {
        self.bpm = bpm.clamped(to: Self.bpmRange)
        self.beatsPerChord = beatsPerChord.clamped(to: Self.beatsPerChordRange)
        self.preventBackToBackRepeat = preventBackToBackRepeat
        self.countInEnabled = countInEnabled
        self.metronomeSoundEnabled = metronomeSoundEnabled
        self.durationGoal = durationGoal
        self.accentFirstBeat = accentFirstBeat
    }

    /// Prepares the configuration for a new session after returning home.
    /// Tempo, beats, goal and accent go back to their defaults; the
    /// repeat, count-in and sound switches are kept because they behave
    /// like the user's standing preferences.
    mutating func resetForNewSession(defaultBPM: Int, defaultBeatsPerChord: Int) {
        bpm = defaultBPM
        beatsPerChord = defaultBeatsPerChord
        durationGoal = .tenMinutes
        accentFirstBeat = true
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

enum PracticeDurationGoal: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case unlimited = 0

    var id: Int { rawValue }

    var minutes: Int? {
        self == .unlimited ? nil : rawValue
    }

    var seconds: Int? {
        minutes.map { $0 * 60 }
    }

    var title: String {
        guard let minutes else { return String(localized: "Süresiz") }
        return String(format: String(localized: "%lld dk"), minutes)
    }

    init(minutes: Int?) {
        self = minutes.flatMap(PracticeDurationGoal.init(rawValue:)) ?? .unlimited
    }
}

enum PracticeGoalCalculator {
    static func remainingSeconds(
        elapsedSeconds: Int,
        goal: PracticeDurationGoal
    ) -> Int? {
        guard let targetMinutes = goal.minutes else { return nil }
        return max(0, targetMinutes * 60 - elapsedSeconds)
    }

    static func isCompleted(
        elapsedSeconds: Int,
        goal: PracticeDurationGoal
    ) -> Bool {
        guard let targetMinutes = goal.minutes else { return false }
        return elapsedSeconds >= targetMinutes * 60
    }

    static func recordedDurationSeconds(
        elapsedSeconds: Int,
        goal: PracticeDurationGoal,
        goalReached: Bool
    ) -> Int {
        let elapsedSeconds = max(0, elapsedSeconds)
        guard goalReached, let targetMinutes = goal.minutes else {
            return elapsedSeconds
        }

        // Preserve real overtime when a shorter goal is selected during the
        // session, while avoiding a 04:59 summary from subsecond rounding when
        // a five-minute timer fires exactly at its boundary.
        return max(elapsedSeconds, targetMinutes * 60)
    }
}
