//
//  PitchDetector.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import Foundation

/// Estimates the fundamental frequency of a mono audio buffer using the YIN
/// algorithm. Plain math, no AVFoundation — kept separate from `TunerEngine`
/// so it can be reasoned about (and tested) without a microphone.
///
/// Reference: de Cheveigné & Kawahara, "YIN, a fundamental frequency
/// estimator for speech and music" (2002).
enum PitchDetector {
    /// Below this the buffer is considered too ambiguous to be a real pitch
    /// (silence, noise, or an inharmonic pluck transient).
    private static let clarityThreshold = 0.15

    /// Guitar's lowest open string (E2 ≈ 82Hz) sets the floor; anything lower
    /// would need a longer window than we buffer.
    private static let minFrequency = 70.0
    private static let maxFrequency = 1000.0

    static func detectPitch(buffer: [Float], sampleRate: Double) -> Double? {
        let maxLag = min(buffer.count - 1, Int(sampleRate / minFrequency))
        let minLag = max(1, Int(sampleRate / maxFrequency))
        guard maxLag > minLag else { return nil }

        // Step 1+2: difference function, cumulative mean normalized.
        var difference = [Double](repeating: 0, count: maxLag + 1)
        for lag in 1...maxLag {
            var sum = 0.0
            for i in 0..<(buffer.count - lag) {
                let delta = Double(buffer[i]) - Double(buffer[i + lag])
                sum += delta * delta
            }
            difference[lag] = sum
        }

        var normalized = [Double](repeating: 1, count: maxLag + 1)
        var runningSum = 0.0
        for lag in 1...maxLag {
            runningSum += difference[lag]
            normalized[lag] = runningSum == 0 ? 1 : difference[lag] * Double(lag) / runningSum
        }

        // Step 3: absolute threshold — first dip below threshold, or if none
        // qualifies, the global minimum (best-effort fallback).
        var bestLag = -1
        var lag = minLag
        while lag <= maxLag {
            if normalized[lag] < clarityThreshold {
                // Walk to the local minimum around this dip.
                while lag + 1 <= maxLag && normalized[lag + 1] < normalized[lag] {
                    lag += 1
                }
                bestLag = lag
                break
            }
            lag += 1
        }

        if bestLag == -1 {
            guard let minIndex = normalized[minLag...maxLag].indices.min(by: { normalized[$0] < normalized[$1] }),
                  normalized[minIndex] < 0.5 else {
                return nil
            }
            bestLag = minIndex
        }

        // Step 4: parabolic interpolation around bestLag for sub-sample precision.
        let refinedLag = parabolicInterpolation(around: bestLag, in: normalized)
        guard refinedLag > 0 else { return nil }

        let frequency = sampleRate / refinedLag
        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }
        return frequency
    }

    private static func parabolicInterpolation(around lag: Int, in values: [Double]) -> Double {
        guard lag > 0, lag < values.count - 1 else { return Double(lag) }
        let s0 = values[lag - 1]
        let s1 = values[lag]
        let s2 = values[lag + 1]
        let denominator = 2 * s1 - s2 - s0
        guard denominator != 0 else { return Double(lag) }
        let shift = (s2 - s0) / (2 * denominator)
        return Double(lag) + shift
    }
}
