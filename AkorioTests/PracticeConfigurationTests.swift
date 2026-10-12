import Testing
@testable import Akorio

struct PracticeConfigurationTests {
    @Test("Duration goals calculate remaining practice time")
    func remainingPracticeTime() {
        #expect(
            PracticeGoalCalculator.remainingSeconds(
                elapsedSeconds: 125,
                goal: .fiveMinutes
            ) == 175
        )
        #expect(
            PracticeGoalCalculator.remainingSeconds(
                elapsedSeconds: 400,
                goal: .fiveMinutes
            ) == 0
        )
        #expect(
            PracticeGoalCalculator.remainingSeconds(
                elapsedSeconds: 125,
                goal: .unlimited
            ) == nil
        )
    }

    @Test("A duration goal completes only at its target")
    func durationGoalCompletion() {
        #expect(!PracticeGoalCalculator.isCompleted(elapsedSeconds: 299, goal: .fiveMinutes))
        #expect(PracticeGoalCalculator.isCompleted(elapsedSeconds: 300, goal: .fiveMinutes))
        #expect(!PracticeGoalCalculator.isCompleted(elapsedSeconds: 3_600, goal: .unlimited))
    }

    @Test("Stored duration values map back to supported goals")
    func storedDurationMapping() {
        #expect(PracticeDurationGoal(minutes: 10) == .tenMinutes)
        #expect(PracticeDurationGoal(minutes: nil) == .unlimited)
        #expect(PracticeDurationGoal(minutes: 7) == .unlimited)
    }
}
