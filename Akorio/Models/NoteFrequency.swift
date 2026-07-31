//
//  NoteFrequency.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import Foundation

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
        noteName = Self.noteNames[((midiNote % 12) + 12) % 12]
        octave = midiNote / 12 - 1
    }
}
