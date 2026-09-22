//
//  ChordPlaybackEngine.swift
//  Akorio
//

import AVFoundation

/// Plays the notes represented by a guitar fingering. This is intentionally
/// a small synthesized preview rather than a bundled recording: it works for
/// every explicit shape and keeps the app size small.
final class ChordPlaybackEngine {
    private let engine = AVAudioEngine()
    private let mixer: AVAudioMixerNode
    private var players: [AVAudioPlayerNode] = []
    private var generation = 0
    private let sampleRate = 44_100.0

    // Standard tuning, low E to high E.
    private let openStringFrequencies = [82.4069, 110.0, 146.832, 195.998, 246.942, 329.628]

    init() {
        mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        for _ in 0..<6 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
            players.append(player)
        }
    }

    func play(shape: ChordShape) {
        stop()
        generation += 1
        let currentGeneration = generation

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try? engine.start() }

        for (index, fret) in shape.frets.enumerated() {
            guard let fret else { continue }
            let frequency = openStringFrequencies[index] * pow(2.0, Double(fret) / 12.0)
            let buffer = makeBuffer(frequency: frequency)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.035) { [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                self.players[index].scheduleBuffer(buffer, at: nil, options: .interrupts)
                self.players[index].play()
            }
        }
    }

    func stop() {
        generation += 1
        players.forEach { $0.stop() }
    }

    private func makeBuffer(frequency: Double) -> AVAudioPCMBuffer {
        let duration = 1.7
        let format = mixer.outputFormat(forBus: 0)
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let channelCount = Int(format.channelCount)
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let attack = min(1.0, time / 0.008)
            let decay = exp(-time / 0.65)
            let sample = Float(sin(2.0 * .pi * frequency * time) * attack * decay * 0.14)
            for channel in 0..<channelCount {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        return buffer
    }
}
