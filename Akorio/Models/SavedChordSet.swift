//
//  SavedChordSet.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation
import SwiftData

@Model
final class SavedChordSet {
    var id: UUID
    var name: String
    var chordLabels: [String]
    var bpm: Int
    var beatsPerChord: Int
    // Defaulted (not just set in init) so SwiftData can lightweight-migrate
    // existing rows when this attribute is added to the schema, instead of
    // crashing with "missing attribute values on mandatory destination
    // attribute" the way it did without a default.
    var preventBackToBackRepeat: Bool = true
    var countInEnabled: Bool
    var metronomeSoundEnabled: Bool
    var createdAt: Date

    init(
        name: String,
        chordLabels: [String],
        bpm: Int,
        beatsPerChord: Int,
        preventBackToBackRepeat: Bool,
        countInEnabled: Bool,
        metronomeSoundEnabled: Bool
    ) {
        self.id = UUID()
        self.name = name
        self.chordLabels = chordLabels
        self.bpm = bpm
        self.beatsPerChord = beatsPerChord
        self.preventBackToBackRepeat = preventBackToBackRepeat
        self.countInEnabled = countInEnabled
        self.metronomeSoundEnabled = metronomeSoundEnabled
        self.createdAt = Date()
    }

    var subtitle: String {
        let chordsPart = chordLabels.isEmpty ? "—" : chordLabels.joined(separator: ", ")
        return "\(chordsPart) · \(bpm) BPM"
    }
}
