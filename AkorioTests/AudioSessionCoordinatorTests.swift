import Testing
@testable import Akorio

@MainActor
struct AudioSessionCoordinatorTests {
    private final class FakeDriver: AudioSessionDriver {
        var configured: [AudioSessionMode] = []
        var activations = 0
        var failsConfigure = false

        struct Failure: Error {}

        func configure(_ mode: AudioSessionMode) throws {
            if failsConfigure { throw Failure() }
            configured.append(mode)
        }

        func activate() throws { activations += 1 }
    }

    @Test("Playback is the default mode")
    func defaultsToPlayback() throws {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)

        try coordinator.prepareForPlayback()

        #expect(coordinator.desiredMode == .playback)
        #expect(driver.configured == [.playback])
        #expect(driver.activations == 1)
    }

    @Test("Tuning switches to the microphone mode and back to playback")
    func tuningRoundTrip() throws {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)
        try coordinator.prepareForPlayback()

        try coordinator.beginTuning()
        #expect(coordinator.desiredMode == .tuning)

        coordinator.endTuning()
        #expect(coordinator.desiredMode == .playback)
        #expect(driver.configured == [.playback, .tuning, .playback])
    }

    @Test("Metronome setup during tuning does not steal the session")
    func playbackDuringTuningKeepsTuning() throws {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)
        try coordinator.beginTuning()

        try coordinator.prepareForPlayback()

        #expect(driver.configured == [.tuning])
    }

    @Test("The category is only set again when the mode changes")
    func skipsRedundantConfiguration() throws {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)

        try coordinator.prepareForPlayback()
        try coordinator.prepareForPlayback()

        #expect(driver.configured == [.playback])
        #expect(driver.activations == 2)
    }

    @Test("A failed switch to tuning leaves playback in charge")
    func failedTuningFallsBack() throws {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)
        driver.failsConfigure = true

        #expect(throws: FakeDriver.Failure.self) {
            try coordinator.beginTuning()
        }
        #expect(coordinator.desiredMode == .playback)
    }

    @Test("Ending tuning without having started does nothing")
    func endWithoutBegin() {
        let driver = FakeDriver()
        let coordinator = AudioSessionCoordinator(driver: driver)

        coordinator.endTuning()

        #expect(driver.configured.isEmpty)
        #expect(driver.activations == 0)
    }

    @Test("Modes map to the expected categories")
    func modeCategories() {
        #expect(AudioSessionMode.playback.category == .ambient)
        #expect(AudioSessionMode.tuning.category == .playAndRecord)
    }
}
