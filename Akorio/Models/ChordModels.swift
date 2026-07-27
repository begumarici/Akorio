//
//  ChordModels.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation

let akorioRootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

struct ChordType: Identifiable {
    let key: String
    let display: String
    let suffix: String
    var id: String { key }
}

let akorioCommonTypes: [ChordType] = [
    ChordType(key: "maj", display: "Major", suffix: ""),
    ChordType(key: "min", display: "minor", suffix: "m"),
    ChordType(key: "7", display: "7", suffix: "7"),
    ChordType(key: "maj7", display: "maj7", suffix: "maj7"),
    ChordType(key: "m7", display: "m7", suffix: "m7"),
    ChordType(key: "sus4", display: "sus4", suffix: "sus4"),
]

let akorioMoreTypes: [ChordType] = [
    ChordType(key: "dim", display: "dim", suffix: "dim"),
    ChordType(key: "aug", display: "aug", suffix: "aug"),
    ChordType(key: "sus2", display: "sus2", suffix: "sus2"),
    ChordType(key: "9", display: "9", suffix: "9"),
]

struct ChordItem: Identifiable, Equatable {
    let label: String
    var id: String { label }
}

enum OrderMode: String, Codable, CaseIterable, Hashable {
    case sequential
    case random
    case randomNoRepeat

    var label: String {
        switch self {
        case .sequential: return "Sırayla"
        case .random: return "Karışık"
        case .randomNoRepeat: return "Karışık (tekrarsız)"
        }
    }
}

enum MetronomeSound: String, Codable, CaseIterable, Hashable {
    case click
    case wood
    case beep

    var label: String {
        switch self {
        case .click: return "Klasik Klik"
        case .wood: return "Tahta Blok"
        case .beep: return "Bip"
        }
    }
}
