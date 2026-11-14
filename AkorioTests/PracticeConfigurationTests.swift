import SwiftData
import Testing
@testable import Akorio

struct PracticeConfigurationTests {
    @Test("Tempo and beats stay inside their supported ranges")
    func valuesAreClamped() {
        var configuration = PracticeConfiguration(bpm: 10, beatsPerChord: 20)
        #expect(configuration.bpm == 40)
        #expect(configuration.beatsPerChord == 8)

        configuration.bpm = 500
        configuration.beatsPerChord = 0
        #expect(configuration.bpm == 240)
        #expect(configuration.beatsPerChord == 1)
    }

    @Test("Starting a new session resets tempo but keeps standing preferences")
    func resetForNewSession() {
        var configuration = PracticeConfiguration(
            bpm: 150,
            beatsPerChord: 2,
            preventBackToBackRepeat: false,
            countInEnabled: false,
            metronomeSoundEnabled: false,
            durationGoal: .twentyMinutes,
            accentFirstBeat: false
        )

        configuration.resetForNewSession(defaultBPM: 90, defaultBeatsPerChord: 3)

        #expect(configuration == PracticeConfiguration(
            bpm: 90,
            beatsPerChord: 3,
            preventBackToBackRepeat: false,
            countInEnabled: false,
            metronomeSoundEnabled: false,
            durationGoal: .tenMinutes,
            accentFirstBeat: true
        ))
    }

    @Test("Saved sets and the last session round-trip every option")
    func persistenceRoundTrip() throws {
        let container = try ModelContainer(
            for: SavedChordSet.self, AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let configuration = PracticeConfiguration(
            bpm: 123,
            beatsPerChord: 6,
            preventBackToBackRepeat: false,
            countInEnabled: false,
            metronomeSoundEnabled: false,
            durationGoal: .fifteenMinutes,
            accentFirstBeat: false
        )

        let savedSet = SavedChordSet(name: "Test", chordLabels: ["Am"], configuration: configuration)
        context.insert(savedSet)
        #expect(savedSet.configuration == configuration)

        let settings = AppSettings()
        context.insert(settings)
        settings.lastPracticeConfiguration = configuration
        #expect(settings.lastPracticeConfiguration == configuration)
    }

    @Test("Duration goals expose their length in seconds")
    func durationGoalSeconds() {
        #expect(PracticeDurationGoal.fiveMinutes.seconds == 300)
        #expect(PracticeDurationGoal.unlimited.seconds == nil)
    }

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

    @Test("Recorded duration preserves real elapsed practice time")
    func recordedDuration() {
        #expect(
            PracticeGoalCalculator.recordedDurationSeconds(
                elapsedSeconds: 360,
                goal: .fiveMinutes,
                goalReached: true
            ) == 360
        )
        #expect(
            PracticeGoalCalculator.recordedDurationSeconds(
                elapsedSeconds: 299,
                goal: .fiveMinutes,
                goalReached: true
            ) == 300
        )
        #expect(
            PracticeGoalCalculator.recordedDurationSeconds(
                elapsedSeconds: 125,
                goal: .fiveMinutes,
                goalReached: false
            ) == 125
        )
    }
}
