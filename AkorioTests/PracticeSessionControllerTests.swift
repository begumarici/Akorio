import SwiftData
import Testing
@testable import Akorio

@MainActor
struct PracticeSessionControllerTests {
    private func makeController() throws -> (PracticeSessionController, ModelContext, AppSettings) {
        let container = try ModelContainer(
            for: AppSettings.self, PracticeSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let settings = AppSettings.fetchOrCreate(in: context)
        let controller = PracticeSessionController()
        controller.attach(context: context, settings: settings)
        return (controller, context, settings)
    }

    private func addSessions(_ count: Int, to context: ModelContext) {
        for _ in 0..<count {
            context.insert(PracticeSession(
                durationSeconds: 60,
                chordTransitionCount: 10,
                bpm: 80,
                beatsPerChord: 4,
                chordLabels: ["Am"],
                targetDurationMinutes: nil,
                goalCompleted: false
            ))
        }
    }

    @Test("Starting opens the practice screen with a clean session")
    func startClearsState() throws {
        let (controller, _, _) = try makeController()
        controller.isPaused = true
        controller.showExitAlert = true

        controller.start()

        #expect(controller.isPresented)
        #expect(!controller.isPaused)
        #expect(!controller.showExitAlert)
        #expect(controller.currentSummary == nil)
    }

    @Test("Leaving before anything started closes the screen without asking")
    func exitWithoutProgress() throws {
        let (controller, _, _) = try makeController()
        controller.start()
        var willCloseCalls = 0
        controller.willClose = { willCloseCalls += 1 }

        controller.requestExit()

        #expect(!controller.isPresented)
        #expect(!controller.showExitAlert)
        #expect(willCloseCalls == 1)
    }

    @Test("Confirming an exit closes the screen and remembers the plan")
    func confirmExit() throws {
        let (controller, _, _) = try makeController()
        controller.start()
        controller.showExitAlert = true
        var willCloseCalls = 0
        controller.willClose = { willCloseCalls += 1 }

        controller.confirmExit()

        #expect(!controller.isPresented)
        #expect(!controller.showExitAlert)
        #expect(willCloseCalls == 1)
    }

    @Test("Finishing with no elapsed time records nothing")
    func emptyFinishIsIgnored() throws {
        let (controller, context, _) = try makeController()

        controller.finish()

        #expect(controller.currentSummary == nil)
        #expect(try context.fetchCount(FetchDescriptor<PracticeSession>()) == 0)
    }

    @Test("A review is requested once enough sessions are recorded")
    func reviewRequestedWhenEligible() throws {
        let (controller, context, _) = try makeController()

        addSessions(1, to: context)
        controller.requestReviewIfEligible()
        #expect(!controller.shouldRequestReview)

        addSessions(4, to: context)
        controller.requestReviewIfEligible()
        #expect(controller.shouldRequestReview)
    }

    @Test("Handling the review request stores that it was asked")
    func reviewHandled() throws {
        let (controller, context, settings) = try makeController()
        addSessions(5, to: context)
        controller.requestReviewIfEligible()

        controller.reviewRequestWasHandled()

        #expect(!controller.shouldRequestReview)
        #expect(settings.hasRequestedAppStoreReview)

        controller.requestReviewIfEligible()
        #expect(!controller.shouldRequestReview)
    }
}
