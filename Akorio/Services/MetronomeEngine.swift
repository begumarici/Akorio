//
//  MetronomeEngine.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation
import Observation
import UIKit

/// Owns the real-time practice session: the count-in, the chord loop timer,
/// and triggering clicks (sound + haptic). Kept separate from `AppViewModel`
/// because it's a genuinely different kind of concern — a stateful engine
/// with its own `Timer`, not app navigation/CRUD.
@Observable
final class MetronomeEngine {
    /// The live settings a session needs, read fresh on every tick via
    /// `configurationProvider` — `AppViewModel` still owns the actual values
    /// (Selector/Settings screens need them too), so nothing is duplicated.
    struct Configuration {
        let chordLabels: [String]
        let bpm: Int
        let beatsPerChord: Int
        let preventBackToBackRepeat: Bool
        let countInEnabled: Bool
        let metronomeSoundEnabled: Bool
        let metronomeSound: MetronomeSound
        let hapticEnabled: Bool
        let targetDurationSeconds: Int?
        let accentFirstBeat: Bool
    }

    var isPlaying = false
    var isCountingIn = false
    var countInBeatsLeft = 0
    var currentChordLabel = ""
    var nextChordLabel = ""
    var beatInCurrentChord = -1

    /// Set once by `AppViewModel` at startup.
    var configurationProvider: () -> Configuration = {
        Configuration(
            chordLabels: [], bpm: 80, beatsPerChord: 4, preventBackToBackRepeat: true,
            countInEnabled: true, metronomeSoundEnabled: true, metronomeSound: .click, hapticEnabled: false,
            targetDurationSeconds: nil, accentFirstBeat: true
        )
    }

    var goalReachedHandler: () -> Void = {}

    private let toneEngine = ToneEngine()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private var timer: Timer?
    private var currentBeatInterval: TimeInterval = 0
    private var loopBeat = 0
    private var loopCurrent = ""
    private var loopNext = ""
    private var countInLeft = 0
    private(set) var practiceStartedAt: Date?
    private(set) var chordTransitionCount = 0

    private var accumulatedPracticeDuration: TimeInterval = 0

    var hasStartedPractice: Bool {
        practiceStartedAt != nil || accumulatedPracticeDuration > 0
    }

    var elapsedPracticeSeconds: Int {
        max(0, Int(elapsedPracticeDuration))
    }

    private var elapsedPracticeDuration: TimeInterval {
        let activeDuration = practiceStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        return accumulatedPracticeDuration + activeDuration
    }

    func toggle() {
        if isPlaying {
            stop()
            return
        }

        let config = configurationProvider()
        guard !config.chordLabels.isEmpty else { return }

        practiceStartedAt = nil
        chordTransitionCount = 0
        accumulatedPracticeDuration = 0

        let beatSeconds = 60.0 / Double(config.bpm)
        // The first chord is always the first one the user selected — not
        // randomized — so whatever's shown as "next" before the session
        // starts is guaranteed to be what actually plays first.
        let first = config.chordLabels[0]
        let second = pickNextChord(from: config, excluding: first)

        if config.countInEnabled {
            countInLeft = config.beatsPerChord
            loopCurrent = first
            loopNext = second
            currentBeatInterval = beatSeconds
            isPlaying = true
            isCountingIn = true
            countInBeatsLeft = countInLeft
            currentChordLabel = first
            nextChordLabel = second
            beatInCurrentChord = 0
            playClick(accent: config.accentFirstBeat, config: config)
            scheduleTimer(interval: beatSeconds) { [weak self] in self?.countInTick() }
        } else {
            isPlaying = true
            isCountingIn = false
            currentChordLabel = first
            nextChordLabel = second
            beatInCurrentChord = 0
            playClick(accent: config.accentFirstBeat, config: config)
            startChordLoop(first: first, second: second, config: config)
        }
    }

    func stop() {
        if let practiceStartedAt {
            accumulatedPracticeDuration += Date().timeIntervalSince(practiceStartedAt)
            self.practiceStartedAt = nil
        }

        stopTimer()
        isPlaying = false
        isCountingIn = false
        // Clear the chord state too — otherwise the next time this screen
        // appears (possibly with a totally different chord selection) it
        // would briefly show stale labels left over from the last session.
        currentChordLabel = ""
        nextChordLabel = ""
        beatInCurrentChord = -1
    }

    func pause() {
        guard isPlaying else { return }

        if let practiceStartedAt {
            accumulatedPracticeDuration += Date().timeIntervalSince(practiceStartedAt)
            self.practiceStartedAt = nil
        }

        stopTimer()
        isPlaying = false
        isCountingIn = false
    }

    func resume() {
        guard !isPlaying else { return }

        let config = configurationProvider()
        guard !config.chordLabels.isEmpty else { return }

        currentBeatInterval = 60.0 / Double(config.bpm)
        isPlaying = true

        currentChordLabel = loopCurrent
        nextChordLabel = loopNext
        loopBeat = 0
        beatInCurrentChord = 0

        if config.countInEnabled {
            countInLeft = config.beatsPerChord
            countInBeatsLeft = countInLeft
            isCountingIn = true

            playClick(accent: config.accentFirstBeat, config: config)

            scheduleTimer(interval: currentBeatInterval) { [weak self] in
                self?.countInTick()
            }
        } else {
            isCountingIn = false
            practiceStartedAt = Date()

            scheduleTimer(interval: currentBeatInterval) { [weak self] in
                self?.chordLoopTick()
            }
        }
    }

    private func pickNextChord(from config: Configuration, excluding: String?) -> String {
        let labels = config.chordLabels
        guard !labels.isEmpty else { return "" }
        if labels.count == 1 { return labels[0] }

        guard config.preventBackToBackRepeat else {
            return labels.randomElement() ?? ""
        }
        var pool = labels
        if let excluding {
            pool.removeAll { $0 == excluding }
        }
        if pool.isEmpty { pool = labels }
        return pool.randomElement() ?? ""
    }

    private func countInTick() {
        let config = configurationProvider()
        countInLeft -= 1
        if countInLeft > 0 {
            countInBeatsLeft = countInLeft
            playClick(accent: false, config: config)
            rearmIfTempoChanged(config: config) { [weak self] in self?.countInTick() }
        } else {
            stopTimer()
            isCountingIn = false
            playClick(accent: config.accentFirstBeat, config: config)
            startChordLoop(first: loopCurrent, second: loopNext, config: config)
        }
    }

    private func chordLoopTick() {
        let config = configurationProvider()
        loopBeat += 1
        if loopBeat >= config.beatsPerChord {
            loopBeat = 0

            let previousChord = loopCurrent
            loopCurrent = loopNext
            loopNext = pickNextChord(from: config, excluding: loopCurrent)

            if loopCurrent != previousChord {
                chordTransitionCount += 1
            }

            currentChordLabel = loopCurrent
            nextChordLabel = loopNext
            beatInCurrentChord = loopBeat
        } else {
            beatInCurrentChord = loopBeat
        }

        playClick(accent: config.accentFirstBeat && loopBeat == 0, config: config)

        if let target = config.targetDurationSeconds,
           elapsedPracticeDuration >= TimeInterval(target) {
            goalReachedHandler()
            return
        }

        rearmIfTempoChanged(config: config) { [weak self] in self?.chordLoopTick() }
    }

    private func startChordLoop(first: String, second: String, config: Configuration) {
        if practiceStartedAt == nil {
            practiceStartedAt = Date()
        }
        loopBeat = 0
        loopCurrent = first
        loopNext = second
        currentBeatInterval = 60.0 / Double(config.bpm)
        scheduleTimer(interval: currentBeatInterval) { [weak self] in self?.chordLoopTick() }
    }

    private func scheduleTimer(interval: TimeInterval, _ tick: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in tick() }
    }

    /// If the user changed the BPM mid-session, re-arm the timer at the new
    /// interval on the next beat instead of waiting for it to stop and restart.
    private func rearmIfTempoChanged(config: Configuration, _ tick: @escaping () -> Void) {
        let wanted = 60.0 / Double(config.bpm)
        if abs(wanted - currentBeatInterval) > 0.0001 {
            currentBeatInterval = wanted
            scheduleTimer(interval: wanted, tick)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func playClick(accent: Bool, config: Configuration) {
        if config.hapticEnabled {
            hapticGenerator.impactOccurred(intensity: accent ? 1.0 : 0.5)
        }
        guard config.metronomeSoundEnabled else { return }
        toneEngine.play(config.metronomeSound, accent: accent)
    }
}
