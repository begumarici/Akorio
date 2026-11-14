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
    var targetDurationMinutes: Int? = nil
    var accentFirstBeat: Bool = true
    var createdAt: Date

    init(
        name: String,
        chordLabels: [String],
        configuration: PracticeConfiguration
    ) {
        self.id = UUID()
        self.name = name
        self.chordLabels = chordLabels
        self.bpm = configuration.bpm
        self.beatsPerChord = configuration.beatsPerChord
        self.preventBackToBackRepeat = configuration.preventBackToBackRepeat
        self.countInEnabled = configuration.countInEnabled
        self.metronomeSoundEnabled = configuration.metronomeSoundEnabled
        self.targetDurationMinutes = configuration.durationGoal.minutes
        self.accentFirstBeat = configuration.accentFirstBeat
        self.createdAt = Date()
    }

    /// The stored columns stay flat so existing databases keep loading;
    /// the rest of the app reads them through this single value.
    var configuration: PracticeConfiguration {
        PracticeConfiguration(
            bpm: bpm,
            beatsPerChord: beatsPerChord,
            preventBackToBackRepeat: preventBackToBackRepeat,
            countInEnabled: countInEnabled,
            metronomeSoundEnabled: metronomeSoundEnabled,
            durationGoal: PracticeDurationGoal(minutes: targetDurationMinutes),
            accentFirstBeat: accentFirstBeat
        )
    }

    var subtitle: String {
        let chordsPart = chordLabels.isEmpty ? "—" : chordLabels.joined(separator: ", ")
        return "\(chordsPart) · \(bpm) BPM"
    }
}
