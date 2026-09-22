//
//  ChordQuality.swift
//  Akorio
//
//  Created by Begüm Arıcı on 15.09.2026.
//

import Foundation

enum ChordQuality: String, CaseIterable, Hashable, Identifiable {
    case major
    case minor
    case seventh
    case power
    case majorSeventh
    case minorSeventh
    case sus2
    case sus4
    case dominantSus4
    case diminished
    case diminishedSeventh
    case augmented

    var id: String { rawValue }

    var intervals: [Int] {
        switch self {
        case .major: return [0, 4, 7]
        case .minor: return [0, 3, 7]
        case .seventh: return [0, 4, 7, 10]
        case .power: return [0, 7]
        case .majorSeventh: return [0, 4, 7, 11]
        case .minorSeventh: return [0, 3, 7, 10]
        case .sus2: return [0, 2, 7]
        case .sus4: return [0, 5, 7]
        case .dominantSus4: return [0, 5, 7, 10]
        case .diminished: return [0, 3, 6]
        case .diminishedSeventh: return [0, 3, 6, 9]
        case .augmented: return [0, 4, 8]
        }
    }

    var labelSuffix: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .seventh: return "7"
        case .power: return "5"
        case .majorSeventh: return "maj7"
        case .minorSeventh: return "m7"
        case .sus2: return "sus2"
        case .sus4: return "sus4"
        case .dominantSus4: return "7sus4"
        case .diminished: return "dim"
        case .diminishedSeventh: return "dim7"
        case .augmented: return "aug"
        }
    }

    var displayName: String {
        switch self {
        case .major: return String(localized: "Majör")
        case .minor: return String(localized: "Minör")
        case .seventh: return String(localized: "7")
        case .power: return String(localized: "5")
        case .majorSeventh: return String(localized: "Maj7")
        case .minorSeventh: return String(localized: "m7")
        case .sus2: return String(localized: "Sus2")
        case .sus4: return String(localized: "Sus4")
        case .dominantSus4: return String(localized: "7sus4")
        case .diminished: return String(localized: "Dim")
        case .diminishedSeventh: return String(localized: "Dim7")
        case .augmented: return String(localized: "Aug")
        }
    }
}

struct ChordIdentity: Hashable, Identifiable {
    let root: String
    let quality: ChordQuality

    var id: String { label }

    var label: String { root + quality.labelSuffix }

    var noteNames: [String] {
        guard let rootIndex = akorioRootNotes.firstIndex(of: root) else { return [root] }
        return quality.intervals.map { interval in
            akorioRootNotes[(rootIndex + interval) % 12]
        }
    }
}
