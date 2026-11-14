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
            // `cents` measures distance to the nearest CHROMATIC note, so an
            // in-tune F4 reads as 0 cents while `closestGuitarString` still
            // maps it to the nearest string (E4) — without this check, playing
            // any in-tune note would falsely lock whatever string is closest.
            // The note must actually BE the string's note; then `cents` and
            // cents-from-string are the same number.
            guard pitch.noteName == string.noteName, pitch.octave == string.octave else { return }
            // Only the first time a string crosses into tune — re-checking
            // an already-locked string on every reading would replay the
            // chime for as long as the note keeps ringing in tune.
            guard !lockedStrings.contains(string) else { return }
            lockedStrings.insert(string)
            if lockedStrings.count == GuitarString.allCases.count {
                playAllTunedChime()
            } else {
                playConfirmChime()
            }
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
    private var allTunedChimeBuffer: AVAudioPCMBuffer?
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
    /// buffers queue up behind it (that queue would only grow, and the
    /// display would drift further and further behind real time) — we
    /// always work on the freshest audio instead.
    private let analysisQueue = DispatchQueue(label: "com.akorio.tuner.analysis")
    private var isProcessing = false

    /// Analysis runs over a sliding window 1.5x the tap size: a bigger
    /// window means more string periods per YIN pass, which cuts cents
    /// jitter and sharpens low-string (E2) resolution — but every extra
    /// sample also lengthens the O(window × maxLag) YIN pass, so this stays
    /// well short of a full doubling to keep each pass safely faster than
    /// the ~46ms cadence buffers arrive at. Accessed on `analysisQueue`.
    private let analysisWindowSize = 3072
    private var sampleWindow: [Float] = []

    /// Minimum share of harmonic-ladder energy (1st+2nd / total of 1st-4th)
    /// a candidate frequency must show to be trusted — see the explanation
    /// where this is used in `process(buffer:sampleRate:)`. Set generously
    /// low so it only rejects the near-silent-low-end phantom case, not a
    /// real note whose fundamental happens to be weak.
    private let lowHarmonicRatioThreshold = 0.12

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
    /// Recent same-note readings feeding the display. A median over these
    /// discards the occasional outlier frame outright (an average would let
    /// it drag the needle), then an EMA over the median irons out the
    /// residual ±cents wobble. Main thread only.
    private var recentFrequencies: [Double] = []
    private let medianWindow = 5
    /// EMA state — the frequency actually shown on the gauge.
    private var smoothedFrequency: Double?
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
        AudioSessionCoordinator.shared.endTuning()
        isListening = false
        currentPitch = nil
        pendingFrequency = nil
        quietFrames = 0
        pitchlessFrames = 0
        resetSmoothing()
        analysisQueue.async { [weak self] in
            self?.sampleWindow.removeAll()
        }
    }

    private func beginListening() {
        guard isForeground else { return }
        failedToStart = false

        do {
            try AudioSessionCoordinator.shared.beginTuning()
        } catch {
            failedToStart = true
            return
        }

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            AudioSessionCoordinator.shared.endTuning()
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
            AudioSessionCoordinator.shared.endTuning()
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
            self.sampleWindow.append(contentsOf: samples)
            if self.sampleWindow.count > self.analysisWindowSize {
                self.sampleWindow.removeFirst(self.sampleWindow.count - self.analysisWindowSize)
            }

            // RMS over just the fresh buffer (not the whole window) so pluck
            // detection reacts to what's happening *now*.
            let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
            let rms = (sumOfSquares / Float(samples.count)).squareRoot()

            // Skip YIN entirely below the hold floor — it's the expensive
            // part, and a buffer that quiet is silence either way. Also wait
            // for the window to fill; a partial window would just produce a
            // low-quality reading for one frame.
            var frequency = rms >= self.holdRMS && self.sampleWindow.count >= self.analysisWindowSize
                ? PitchDetector.detectPitch(buffer: self.sampleWindow, sampleRate: sampleRate)
                : nil

            // Two strings ringing together can trick YIN into reporting a
            // note that isn't really sounding: their harmonics can coincide
            // with a lower note's period (the "missing fundamental"
            // illusion — the same thing that fools human hearing; e.g. B3+E4
            // together read almost exactly as E2's own 3rd/4th harmonics).
            // Real polyphonic tuners guard against this by band-limiting
            // around each candidate's own nominal frequency before trusting
            // it. We approximate that here without a real filter: measure
            // how much energy actually sits at the candidate's own 1st/2nd
            // harmonic (which any genuinely vibrating string has) versus its
            // 3rd/4th (where a phantom candidate's *actual* — unrelated —
            // notes would live instead). A real note keeps a meaningful
            // share of energy in the low rungs; a phantom's low rungs are
            // silent because nothing is actually generating them.
            if let f = frequency {
                let window = self.sampleWindow
                let h1 = Self.goertzelMagnitude(window, sampleRate: sampleRate, targetFreq: f)
                let h2 = Self.goertzelMagnitude(window, sampleRate: sampleRate, targetFreq: f * 2)
                let h3 = Self.goertzelMagnitude(window, sampleRate: sampleRate, targetFreq: f * 3)
                let h4 = Self.goertzelMagnitude(window, sampleRate: sampleRate, targetFreq: f * 4)
                let total = h1 + h2 + h3 + h4
                let lowRatio = total > 0 ? (h1 + h2) / total : 0
                if lowRatio < self.lowHarmonicRatioThreshold {
                    frequency = nil
                }
            }

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
            if quietFrames >= 3 {
                currentPitch = nil
                resetSmoothing()
            }
            return
        }
        quietFrames = 0

        guard let frequency else {
            pendingFrequency = nil
            pitchlessFrames += 1
            if pitchlessFrames >= 6 {
                currentPitch = nil
                resetSmoothing()
            }
            return
        }
        pitchlessFrames = 0

        // Same note as displayed (or a slow tuning drift into a neighbor):
        // keep tracking it, even at ring-out volume, through the smoother.
        if let shown = currentPitch?.frequency, cents(between: frequency, and: shown) <= sameNoteCents {
            currentPitch = NotePitch(frequency: smoothed(frequency))
            pendingFrequency = nil
            return
        }

        // A different note (or the first note from a blank display): only
        // accept once two consecutive frames agree AND it arrived with
        // pluck-level loudness. Smoothing restarts from scratch — carrying
        // the old note's EMA over would make the needle glide between notes.
        if let pending = pendingFrequency,
           cents(between: frequency, and: pending) <= agreementCents,
           rms >= acquireRMS {
            resetSmoothing()
            currentPitch = NotePitch(frequency: smoothed(frequency))
            pendingFrequency = nil
            return
        }

        pendingFrequency = frequency
    }

    /// Median-of-recent then EMA. The EMA weight adapts to how far the
    /// median sits from the shown value: near-stationary readings get heavy
    /// smoothing (a still needle on a held note), while a genuine drift —
    /// the user actually turning a peg — gets tracked with little lag.
    private func smoothed(_ frequency: Double) -> Double {
        recentFrequencies.append(frequency)
        if recentFrequencies.count > medianWindow {
            recentFrequencies.removeFirst()
        }
        let median = recentFrequencies.sorted()[recentFrequencies.count / 2]

        guard let previous = smoothedFrequency else {
            smoothedFrequency = median
            return median
        }
        let deviation = cents(between: median, and: previous)
        let alpha = deviation > 6 ? 0.5 : 0.2
        let next = previous + alpha * (median - previous)
        smoothedFrequency = next
        return next
    }

    private func resetSmoothing() {
        recentFrequencies.removeAll()
        smoothedFrequency = nil
    }

    private func cents(between a: Double, and b: Double) -> Double {
        abs(1200 * log2(a / b))
    }

    /// Goertzel algorithm: the magnitude of a single frequency component in
    /// `buffer`, without a full FFT. O(n) per call.
    private static func goertzelMagnitude(_ buffer: [Float], sampleRate: Double, targetFreq: Double) -> Double {
        let n = buffer.count
        let k = Double(n) * targetFreq / sampleRate
        let omega = 2.0 * Double.pi * k / Double(n)
        let cosine = cos(omega)
        let coeff = 2.0 * cosine
        var q0 = 0.0, q1 = 0.0, q2 = 0.0
        for sample in buffer {
            q0 = coeff * q1 - q2 + Double(sample)
            q2 = q1
            q1 = q0
        }
        let real = q1 - q2 * cosine
        let imaginary = q2 * sin(omega)
        return (real * real + imaginary * imaginary).squareRoot() / Double(n)
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

    private func playAllTunedChime() {
        guard isForeground else { return }
        if !engine.isRunning { try? engine.start() }

        let buffer = allTunedChimeBuffer ?? makeAllTunedChimeBuffer()
        allTunedChimeBuffer = buffer
        guard let buffer else { return }

        chimePlayer.stop()
        chimePlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        chimePlayer.play()
    }

    private func makeAllTunedChimeBuffer() -> AVAudioPCMBuffer? {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        // A major arpeggio, C5 up to C6 — a small "ta-da" resolving upward.
        let notes: [(freq: Double, start: Double)] = [
            (523.25, 0), (659.25, 0.09), (783.99, 0.18), (1046.5, 0.30),
        ]
        let noteDuration = 0.22
        let totalDuration = notes.last!.start + noteDuration
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let channelCount = Int(format.channelCount)
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
