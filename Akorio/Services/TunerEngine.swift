//
//  TunerEngine.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import AVFoundation
import UIKit

/// Owns the microphone tap and feeds captured audio through `PitchDetector`,
/// publishing the detected pitch for the tuner UI. The listening counterpart
/// to `ToneEngine` — same crash-guard reasoning (background teardown makes
/// touching the audio engine while backgrounded throw an uncaught exception),
/// mirrored here for the input side.
@Observable
final class TunerEngine {
    enum PermissionState {
        case undetermined, granted, denied
    }

    var isListening = false
    var lockedStrings: Set<GuitarString> = []
    var currentPitch: NotePitch? {
        didSet {
            guard let pitch = currentPitch, abs(pitch.cents) < 5, let string = pitch.closestGuitarString else { return }
            // Only the first time a string crosses into tune — re-checking
            // an already-locked string on every reading would replay the
            // chime for as long as the note keeps ringing in tune.
            guard !lockedStrings.contains(string) else { return }
            lockedStrings.insert(string)
            playConfirmChime()
        }
    }
    var permissionState: PermissionState = .undetermined
    /// Set when the audio session/engine fails to start despite having mic
    /// permission — distinct from `permissionState`, which only tracks
    /// whether the user has said yes to the mic prompt.
    var failedToStart = false

    private let engine = AVAudioEngine()
    
    private let chimePlayer = AVAudioPlayerNode()
    private var chimeBuffer: AVAudioPCMBuffer?
    private var isForeground = true
    /// Whether the tuner screen currently wants to be listening — separate
    /// from `isListening`, which also gets torn down while backgrounded.
    /// Lets `handleWillEnterForeground` know whether to resume.
    private var isActive = false
    private let sampleRate = 44_100.0
    // Small enough to keep updates feeling instant, still several periods of
    // even the lowest guitar string (E2, ~82Hz) for a reliable YIN read.
    private let bufferSize: AVAudioFrameCount = 2048

    /// YIN is too heavy to run on the audio tap's real-time thread — do it
    /// here instead. Guarded by `isProcessing` so a slow analysis never lets
    /// buffers queue up behind it; we always work on the freshest audio.
    private let analysisQueue = DispatchQueue(label: "com.akorio.tuner.analysis")
    private var isProcessing = false

    // MARK: Note tracking
    //
    // Raw per-buffer YIN output is too jumpy to display directly: silence
    // and ambient noise produce phantom notes, a pluck's attack transient
    // misreads for a frame or two, and a decaying string occasionally
    // throws a wild wrong-note frame. The tracker below turns raw readings
    // into a stable display using two ideas:
    //
    // 1. Loudness hysteresis — it takes a *loud* signal (a fresh pluck,
    //    `acquireRMS`) to claim a new note, but only a faint one
    //    (`holdRMS`) to keep tracking the note already shown. Ambient
    //    sound never crosses the acquire bar, and a ringing string's
    //    quiet tail can update cents but can never jump to a different
    //    note — jumping requires the loudness of a new pluck.
    // 2. Two-frame confirmation — a *different* note is only accepted
    //    after two consecutive buffers agree on it (~90ms, still feels
    //    immediate), so a single misread frame can't flicker the display.

    /// Minimum RMS for a reading to claim a NEW note. A deliberate pluck
    /// near the phone easily exceeds this; room chatter does not.
    private let acquireRMS: Float = 0.01
    /// Minimum RMS to keep tracking the note already displayed — much
    /// lower, so the display follows the string's long quiet ring-out.
    private let holdRMS: Float = 0.004
    /// Readings within this many cents of the shown note count as "the
    /// same note wobbling", updated instantly with no confirmation.
    private let sameNoteCents = 80.0
    /// How closely two consecutive frames must agree to confirm a new note.
    private let agreementCents = 40.0

    /// Last frame's reading that didn't match the displayed note — the
    /// candidate awaiting its confirming second frame. Main thread only.
    private var pendingFrequency: Double?
    /// Consecutive near-silent frames; a short run clears the display so a
    /// single dropout between buffers doesn't blank a ringing note.
    private var quietFrames = 0
    /// Consecutive audible-but-unpitched frames (talking, handling noise);
    /// clears the display once it's evidently not a note anymore.
    private var pitchlessFrames = 0

    init() {
        let mixer = engine.mainMixerNode
        engine.attach(chimePlayer)
        engine.connect(chimePlayer, to: mixer, format: mixer.outputFormat(forBus: 0))

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleDidEnterBackground() {
        isForeground = false
        teardown()
    }

    @objc private func handleWillEnterForeground() {
        isForeground = true
        // Only resume if the tuner screen is still the one asking for it —
        // `teardown()` on backgrounding cleared `isListening`, but the user's
        // intent (captured in `isActive`) survives the round trip.
        guard isActive, permissionState == .granted else { return }
        beginListening()
    }

    func start() {
        isActive = true
        guard !isListening else { return }
        failedToStart = false

        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionState = .granted
            beginListening()
        case .denied:
            permissionState = .denied
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.permissionState = granted ? .granted : .denied
                    if granted { self.beginListening() }
                }
            }
        @unknown default:
            permissionState = .denied
        }
    }

    func stop() {
        isActive = false
        teardown()
    }

    private func teardown() {
        guard isListening else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isListening = false
        currentPitch = nil
        pendingFrequency = nil
        quietFrames = 0
        pitchlessFrames = 0
    }

    private func beginListening() {
        guard isForeground else { return }
        failedToStart = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            failedToStart = true
            return
        }

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            failedToStart = true
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer, sampleRate: format.sampleRate)
        }

        do {
            try engine.start()
            isListening = true
        } catch {
            inputNode.removeTap(onBus: 0)
            failedToStart = true
        }
    }

    private func process(buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard !isProcessing, let channelData = buffer.floatChannelData else { return }
        isProcessing = true

        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

        analysisQueue.async { [weak self] in
            guard let self else { return }
            let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
            let rms = (sumOfSquares / Float(samples.count)).squareRoot()
            // Skip YIN entirely below the hold floor — it's the expensive
            // part, and a buffer that quiet is silence either way.
            let frequency = rms >= self.holdRMS
                ? PitchDetector.detectPitch(buffer: samples, sampleRate: sampleRate)
                : nil
            DispatchQueue.main.async {
                self.ingest(frequency: frequency, rms: rms)
                self.isProcessing = false
            }
        }
    }

    private func ingest(frequency: Double?, rms: Float) {
        guard rms >= holdRMS else {
            pendingFrequency = nil
            quietFrames += 1
            if quietFrames >= 3 { currentPitch = nil }
            return
        }
        quietFrames = 0

        guard let frequency else {
            pendingFrequency = nil
            pitchlessFrames += 1
            if pitchlessFrames >= 6 { currentPitch = nil }
            return
        }
        pitchlessFrames = 0

        // Same note as displayed (or a slow tuning drift into a neighbor):
        // track it instantly, even at ring-out volume.
        if let shown = currentPitch?.frequency, cents(between: frequency, and: shown) <= sameNoteCents {
            currentPitch = NotePitch(frequency: frequency)
            pendingFrequency = nil
            return
        }

        // A different note (or the first note from a blank display): only
        // accept once two consecutive frames agree AND it arrived with
        // pluck-level loudness.
        if let pending = pendingFrequency,
           cents(between: frequency, and: pending) <= agreementCents,
           rms >= acquireRMS {
            currentPitch = NotePitch(frequency: frequency)
            pendingFrequency = nil
            return
        }

        pendingFrequency = frequency
    }

    private func cents(between a: Double, and b: Double) -> Double {
        abs(1200 * log2(a / b))
    }

    private func playConfirmChime() {
        guard isForeground else { return }
        if !engine.isRunning { try? engine.start() }

        let buffer = chimeBuffer ?? makeChimeBuffer()
        chimeBuffer = buffer
        guard let buffer else { return }

        chimePlayer.stop()
        chimePlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        chimePlayer.play()
    }

    private func makeChimeBuffer() -> AVAudioPCMBuffer? {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let notes: [(freq: Double, start: Double)] = [(880, 0), (1318.5, 0.07)] // A5, then E6
        let noteDuration = 0.14
        let totalDuration = notes.last!.start + noteDuration
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let channelCount = Int(format.channelCount)
        // The two notes' time ranges overlap (second starts before the
        // first decays out) and get summed below — zero the buffer first
        // so that summation starts from silence, not uninitialized memory.
        for channel in 0..<channelCount {
            buffer.floatChannelData?[channel].update(repeating: 0, count: Int(frameCount))
        }

        let tau = noteDuration / 4.0
        for (freq, start) in notes {
            let startFrame = Int(start * sampleRate)
            let noteFrameCount = Int(noteDuration * sampleRate)
            for i in 0..<noteFrameCount {
                let frame = startFrame + i
                guard frame < Int(frameCount) else { break }
                let t = Double(i) / sampleRate
                let envelope = exp(-t / tau)
                let sample = Float(sin(2.0 * .pi * freq * t) * envelope) * 0.2
                for channel in 0..<channelCount {
                    buffer.floatChannelData?[channel][frame] += sample
                }
            }
        }
        return buffer
    }
}
