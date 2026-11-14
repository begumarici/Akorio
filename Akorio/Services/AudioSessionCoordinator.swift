//
//  AudioSessionCoordinator.swift
//  Akorio
//

import AVFoundation

/// The audio-session settings the app switches between.
enum AudioSessionMode: Equatable {
    /// Metronome clicks: quiet, mixes with other audio, follows the silent switch.
    case playback
    /// Tuner: listens to the microphone and plays its chimes.
    case tuning

    var category: AVAudioSession.Category {
        switch self {
        case .playback: .ambient
        case .tuning: .playAndRecord
        }
    }

    var options: AVAudioSession.CategoryOptions {
        switch self {
        case .playback: [.mixWithOthers]
        case .tuning: [.defaultToSpeaker, .mixWithOthers]
        }
    }
}

/// The two calls the coordinator needs from the system audio session.
/// A protocol so tests can record them instead of touching real audio.
protocol AudioSessionDriver {
    func configure(_ mode: AudioSessionMode) throws
    func activate() throws
}

struct SystemAudioSessionDriver: AudioSessionDriver {
    func configure(_ mode: AudioSessionMode) throws {
        try AVAudioSession.sharedInstance().setCategory(mode.category, options: mode.options)
    }

    func activate() throws {
        try AVAudioSession.sharedInstance().setActive(true)
    }
}

/// The single place that decides how the app's audio session is configured.
/// The metronome and the tuner used to set it independently, so the tuner's
/// microphone category stayed in place after leaving it. Now the tuner only
/// claims the session while it is listening, and everything else gets
/// playback back.
final class AudioSessionCoordinator {
    static let shared = AudioSessionCoordinator(driver: SystemAudioSessionDriver())

    private let driver: AudioSessionDriver
    private var isTuning = false
    private var appliedMode: AudioSessionMode?

    init(driver: AudioSessionDriver) {
        self.driver = driver
    }

    /// What the session should currently be.
    var desiredMode: AudioSessionMode { isTuning ? .tuning : .playback }

    /// Metronome start and return from background: make sure the session is
    /// set up and active for whatever is currently wanted.
    func prepareForPlayback() throws {
        try apply()
    }

    /// The tuner starts listening.
    func beginTuning() throws {
        isTuning = true
        do {
            try apply()
        } catch {
            isTuning = false
            throw error
        }
    }

    /// The tuner stopped listening; back to playback.
    func endTuning() {
        guard isTuning else { return }
        isTuning = false
        try? apply()
    }

    private func apply() throws {
        let mode = desiredMode
        if appliedMode != mode {
            try driver.configure(mode)
            appliedMode = mode
        }
        try driver.activate()
    }
}
