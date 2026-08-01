//
//  NoteFrequency.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import Foundation

/// Standard guitar tuning, low to high — drives both the headstock peg
/// layout (which side/order each string sits in) and which peg the tuner
/// highlights against whatever frequency is currently detected.
enum GuitarString: String, CaseIterable, Identifiable {
    case e2, a2, d3, g3, b3, e4

    var id: String { rawValue }

    var noteName: String {
        switch self {
        case .e2: "E"
        case .a2: "A"
        case .d3: "D"
        case .g3: "G"
        case .b3: "B"
        case .e4: "E"
        }
    }

    var octave: Int {
        switch self {
        case .e2: 2
        case .a2: 2
        case .d3: 3
        case .g3: 3
        case .b3: 3
        case .e4: 4
        }
    }

    /// Standard A4 = 440Hz equal-temperament frequency for this string.
    var frequency: Double {
        switch self {
        case .e2: 82.41
        case .a2: 110.00
        case .d3: 146.83
        case .g3: 196.00
        case .b3: 246.94
        case .e4: 329.63
        }
    }

    /// Physical peg order on a headstock, top to bottom, three per side.
    static let leftPegs: [GuitarString] = [.d3, .a2, .e2]
    static let rightPegs: [GuitarString] = [.g3, .b3, .e4]
}

/// A frequency resolved to the nearest chromatic note plus how far off it is.
struct NotePitch {
    let noteName: String
    let octave: Int
    /// Signed distance from the nearest note, in cents. -50...50 range;
    /// negative is flat, positive is sharp. 100 cents = one semitone.
    let cents: Double
    let frequency: Double

    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// `referenceA4` defaults to the standard concert pitch of 440Hz.
    init?(frequency: Double, referenceA4: Double = 440.0) {
        guard frequency > 0 else { return nil }
        self.frequency = frequency

        // Semitones above/below A4, as a continuous value.
        let semitonesFromA4 = 12.0 * log2(frequency / referenceA4)
        let roundedSemitones = semitonesFromA4.rounded()
        cents = (semitonesFromA4 - roundedSemitones) * 100.0

        // A4 is MIDI note 69; index 9 ("A") in a C-based octave, octave 4.
        let midiNote = Int(roundedSemitones) + 69
        self.midiNote = midiNote
        noteName = Self.noteNames[((midiNote % 12) + 12) % 12]
        octave = midiNote / 12 - 1
    }

    private let midiNote: Int

    /// The guitar string closest in pitch (by octave-aware distance, so a
    /// harmonic doesn't get matched to the wrong string) — highlights the
    /// right peg in the headstock UI.
    var closestGuitarString: GuitarString? {
        GuitarString.allCases.min { lhs, rhs in
            abs(log2(lhs.frequency) - log2(frequency)) < abs(log2(rhs.frequency) - log2(frequency))
        }
    }

    /// The chromatic neighbor one semitone below/above — lets the tuner UI
    /// show whether a played note is drifting toward the previous or next
    /// note, not just how far it is from the nearest one.
    var previousNoteName: String { Self.noteNames[((midiNote - 1) % 12 + 12) % 12] }
    var nextNoteName: String { Self.noteNames[((midiNote + 1) % 12 + 12) % 12] }
}
