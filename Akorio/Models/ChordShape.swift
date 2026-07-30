//
//  ChordShape.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation

/// A fretboard fingering for one chord: one fret position per string,
/// low E to high E. `nil` means muted, `0` means open.
struct ChordShape {
    let frets: [Int?]
    /// The lowest fret shown in the diagram. 1 for chords played at the
    /// nut; higher for barre chords played further up the neck.
    let baseFret: Int
}

/// Looks up (or derives) a fingering for any chord label our curated
/// levels use. A handful of common open shapes are hardcoded; anything
/// else (barre chords like F, B, Bm, F#m, and the full 12-root set on the
/// Expert level) is derived from the open E / Em shape barred up the neck
/// — the standard way guitarists play those chords.
enum ChordShapeLibrary {
    private static let openShapes: [String: [Int?]] = [
        "C": [nil, 3, 2, 0, 1, 0],
        "D": [nil, nil, 0, 2, 3, 2],
        "E": [0, 2, 2, 1, 0, 0],
        "G": [3, 2, 0, 0, 0, 3],
        "A": [nil, 0, 2, 2, 2, 0],
        "Am": [nil, 0, 2, 2, 1, 0],
        "Dm": [nil, nil, 0, 2, 3, 1],
        "Em": [0, 2, 2, 0, 0, 0],
    ]

    /// Chromatic order starting from E, matching the open E-shape barre
    /// chord's root — used to work out how far up the neck to barre.
    private static let chromaticFromE = ["E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#"]

    static func shape(for label: String) -> ChordShape {
        if let frets = openShapes[label] {
            return ChordShape(frets: frets, baseFret: 1)
        }

        let isMinor = label.hasSuffix("m")
        let root = isMinor ? String(label.dropLast()) : label

        guard let barreFret = chromaticFromE.firstIndex(of: root) else {
            return ChordShape(frets: Array(repeating: nil, count: 6), baseFret: 1)
        }

        let template = isMinor ? [0, 2, 2, 0, 0, 0] : [0, 2, 2, 1, 0, 0]
        let frets: [Int?] = template.map { $0 + barreFret }
        return ChordShape(frets: frets, baseFret: max(barreFret, 1))
    }
}
