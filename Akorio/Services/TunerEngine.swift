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
    var currentPitch: NotePitch?
    var permissionState: PermissionState = .undetermined

    private let engine = AVAudioEngine()
    private var isForeground = true
    private let sampleRate = 44_100.0
    // Small enough to keep updates feeling instant, still several periods of
    // even the lowest guitar string (E2, ~82Hz) for a reliable YIN read.
    private let bufferSize: AVAudioFrameCount = 2048

    /// YIN is too heavy to run on the audio tap's real-time thread — do it
    /// here instead. Guarded by `isProcessing` so a slow analysis never lets
    /// buffers queue up behind it; we always work on the freshest audio.
    private let analysisQueue = DispatchQueue(label: "com.akorio.tuner.analysis")
    private var isProcessing = false

    init() {
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
        stop()
    }

    @objc private func handleWillEnterForeground() {
        isForeground = true
    }

    func start() {
        guard !isListening else { return }

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
        guard isListening else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isListening = false
        currentPitch = nil
    }

    private func beginListening() {
        guard isForeground else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer, sampleRate: format.sampleRate)
        }

        do {
            try engine.start()
            isListening = true
        } catch {
            inputNode.removeTap(onBus: 0)
        }
    }

    private func process(buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard !isProcessing, let channelData = buffer.floatChannelData else { return }
        isProcessing = true

        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

        analysisQueue.async { [weak self] in
            let frequency = PitchDetector.detectPitch(buffer: samples, sampleRate: sampleRate)
            let pitch = frequency.flatMap { NotePitch(frequency: $0) }
            DispatchQueue.main.async {
                self?.currentPitch = pitch
                self?.isProcessing = false
            }
        }
    }
}
