//
//  ToneEngine.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import AVFoundation
import UIKit

private enum Waveform {
    case sine
    case square
}

private struct ToneProfile {
    let waveform: Waveform
    let freq: Double
    let accentFreq: Double
    let volume: Float
    let decay: Double
}

private extension MetronomeSound {
    var toneProfile: ToneProfile {
        switch self {
        case .click: ToneProfile(waveform: .sine, freq: 900, accentFreq: 1400, volume: 0.18, decay: 0.08)
        case .wood: ToneProfile(waveform: .square, freq: 400, accentFreq: 600, volume: 0.1, decay: 0.05)
        case .beep: ToneProfile(waveform: .sine, freq: 1000, accentFreq: 1600, volume: 0.15, decay: 0.14)
        }
    }
}

/// Generates and plays short metronome click tones in real time — no audio
/// files bundled, each click is a synthesized sine/square wave with a decay
/// envelope (mirrors the Web Audio oscillator approach from the prototype).
final class ToneEngine {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private var bufferCache: [String: AVAudioPCMBuffer] = [:]
    private let sampleRate = 44_100.0

    /// Backgrounding tears down the session's IO cycle; calling `play()` on a
    /// player node while that's happening throws an uncaught `NSException`
    /// (crash, not a Swift error — can't be caught). This flag is the guard.
    private var isForeground = true

    init() {
        try? AudioSessionCoordinator.shared.prepareForPlayback()

        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
            players.append(player)
        }
        try? engine.start()

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
        engine.pause()
    }

    @objc private func handleWillEnterForeground() {
        isForeground = true
        try? AudioSessionCoordinator.shared.prepareForPlayback()
        try? engine.start()
    }

    func play(_ sound: MetronomeSound, accent: Bool) {
        guard isForeground else { return }
        if !engine.isRunning {
            try? engine.start()
        }

        let key = "\(sound.rawValue)-\(accent)"
        let buffer: AVAudioPCMBuffer
        if let cached = bufferCache[key] {
            buffer = cached
        } else {
            buffer = makeBuffer(profile: sound.toneProfile, accent: accent)
            bufferCache[key] = buffer
        }

        let player = players[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private func makeBuffer(profile: ToneProfile, accent: Bool) -> AVAudioPCMBuffer {
        let freq = accent ? profile.accentFreq : profile.freq
        let duration = profile.decay
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channelCount = Int(format.channelCount)
        let tau = duration / 5.0
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let angle = 2.0 * .pi * freq * t
            let raw: Double
            switch profile.waveform {
            case .sine: raw = sin(angle)
            case .square: raw = sin(angle) >= 0 ? 1.0 : -1.0
            }
            let envelope = exp(-t / tau)
            let sample = Float(raw * envelope) * profile.volume
            for channel in 0..<channelCount {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        return buffer
    }
}
