//
//  PracticeSession.swift
//  Akorio
//
//  Created by Begüm Arıcı on 03.10.2026.
//

import Foundation
import SwiftData

@Model
final class PracticeSession {
    var id: UUID
    var completedAt: Date
    var durationSeconds: Int
    var chordTransitionCount: Int
    var bpm: Int
    var beatsPerChord: Int
    var chordLabels: [String]

    init(
        completedAt: Date = Date(),
        durationSeconds: Int,
        chordTransitionCount: Int,
        bpm: Int,
        beatsPerChord: Int,
        chordLabels: [String]
    ) {
        self.id = UUID()
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.chordTransitionCount = chordTransitionCount
        self.bpm = bpm
        self.beatsPerChord = beatsPerChord
        self.chordLabels = chordLabels
    }
}

struct PracticeStatistics {
    let currentStreak: Int
    let totalDurationSeconds: Int
    let completedSessionCount: Int
}

enum ReviewRequestPolicy {
    static let minimumCompletedSessionCount = 5

    static func isEligible(
        completedSessionCount: Int,
        hasRequestedReview: Bool
    ) -> Bool {
        completedSessionCount >= minimumCompletedSessionCount && !hasRequestedReview
    }
}

enum PracticeStatisticsCalculator {
    static func calculate(
        from sessions: [PracticeSession],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> PracticeStatistics {
        let totalDuration = sessions.reduce(0) { $0 + $1.durationSeconds }
        let practiceDays = Set(sessions.map { calendar.startOfDay(for: $0.completedAt) })
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let latestDay = practiceDays.max()

        guard let latestDay, latestDay == today || latestDay == yesterday else {
            return PracticeStatistics(
                currentStreak: 0,
                totalDurationSeconds: totalDuration,
                completedSessionCount: sessions.count
            )
        }

        var streak = 0
        var cursor = latestDay

        while practiceDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return PracticeStatistics(
            currentStreak: streak,
            totalDurationSeconds: totalDuration,
            completedSessionCount: sessions.count
        )
    }
}
