import Foundation
import Testing
@testable import Akorio

@MainActor
struct PracticeStatisticsCalculatorTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("No sessions produces an empty streak")
    func noSessions() {
        let statistics = calculate(sessions: [], now: date(2026, 10, 9))

        #expect(statistics.currentStreak == 0)
        #expect(statistics.totalDurationSeconds == 0)
        #expect(statistics.completedSessionCount == 0)
    }

    @Test("Consecutive practice days ending today are counted")
    func streakEndingToday() {
        let sessions = [
            session(on: date(2026, 10, 9), duration: 120),
            session(on: date(2026, 10, 8), duration: 180),
            session(on: date(2026, 10, 7), duration: 240),
        ]

        let statistics = calculate(sessions: sessions, now: date(2026, 10, 9))

        #expect(statistics.currentStreak == 3)
        #expect(statistics.totalDurationSeconds == 540)
        #expect(statistics.completedSessionCount == 3)
    }

    @Test("A streak remains active when the latest practice was yesterday")
    func streakEndingYesterday() {
        let sessions = [
            session(on: date(2026, 10, 8)),
            session(on: date(2026, 10, 7)),
            session(on: date(2026, 10, 6)),
        ]

        let statistics = calculate(sessions: sessions, now: date(2026, 10, 9))

        #expect(statistics.currentStreak == 3)
    }

    @Test("Multiple sessions on the same day count as one streak day")
    func duplicatePracticeDays() {
        let sessions = [
            session(on: date(2026, 10, 9, hour: 9)),
            session(on: date(2026, 10, 9, hour: 20)),
            session(on: date(2026, 10, 8)),
        ]

        let statistics = calculate(sessions: sessions, now: date(2026, 10, 9, hour: 22))

        #expect(statistics.currentStreak == 2)
        #expect(statistics.completedSessionCount == 3)
    }

    @Test("A missing day breaks the streak")
    func gapBreaksStreak() {
        let sessions = [
            session(on: date(2026, 10, 9)),
            session(on: date(2026, 10, 7)),
            session(on: date(2026, 10, 6)),
        ]

        let statistics = calculate(sessions: sessions, now: date(2026, 10, 9))

        #expect(statistics.currentStreak == 1)
    }

    @Test("A streak expires after a full missed day")
    func expiredStreak() {
        let sessions = [
            session(on: date(2026, 10, 7)),
            session(on: date(2026, 10, 6)),
        ]

        let statistics = calculate(sessions: sessions, now: date(2026, 10, 9))

        #expect(statistics.currentStreak == 0)
    }

    private func calculate(sessions: [PracticeSession], now: Date) -> PracticeStatistics {
        PracticeStatisticsCalculator.calculate(
            from: sessions,
            now: now,
            calendar: calendar
        )
    }

    private func session(on completedAt: Date, duration: Int = 60) -> PracticeSession {
        PracticeSession(
            completedAt: completedAt,
            durationSeconds: duration,
            chordTransitionCount: 1,
            bpm: 80,
            beatsPerChord: 4,
            chordLabels: ["C"]
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}
