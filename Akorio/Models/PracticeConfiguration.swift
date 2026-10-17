//
//  PracticeConfiguration.swift
//  Akorio
//

import Foundation

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
