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

        // Step 3: pick the period among the convincing dips. Classic YIN
        // takes the first dip below an absolute threshold, but a guitar
        // string's strong 2nd harmonic can carve a dip at HALF the true
        // period that sneaks under the threshold first — reading a whole
        // octave high (E2 shows as E3). The tell: dips at true periods
        // (T, 2T, …) all bottom out near the floor, while a half-period
        // impostor's dip is measurably shallower, because odd harmonics
        // don't repeat there. So: find the deepest dip overall, then take
        // the smallest-lag local minimum that is nearly as deep.
        var deepest = 1.0
        for lag in minLag...maxLag where normalized[lag] < deepest {
            deepest = normalized[lag]
        }
        // No dip below the threshold means no convincing periodicity —
        // report nothing rather than guess; ambient noise stays blank.
        guard deepest < clarityThreshold else { return nil }

        let cutoff = min(max(deepest * 1.6, deepest + 0.03), clarityThreshold)
        var bestLag = -1
        for lag in minLag...maxLag {
            let isLocalMin = normalized[lag] <= normalized[lag - 1]
                && (lag == maxLag || normalized[lag] <= normalized[lag + 1])
            if isLocalMin && normalized[lag] <= cutoff {
                bestLag = lag
                break
            }
        }
        guard bestLag > 0 else { return nil }

        // Step 4: parabolic interpolation around bestLag for sub-sample
        // precision — on the RAW difference function, per the YIN paper:
        // the cumulative-mean normalization multiplies each lag by a
        // different factor, which skews the parabola's vertex and biases
        // the refined period by a few cents.
        let refinedLag = parabolicInterpolation(around: bestLag, in: difference)
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
