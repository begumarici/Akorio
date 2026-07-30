//
//  ChordModels.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation

let akorioRootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

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
