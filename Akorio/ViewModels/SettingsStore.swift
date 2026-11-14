//
//  SettingsStore.swift
//  Akorio
//

import Foundation
import Observation

/// The user's app-wide preferences. Values are mirrored here so screens can
/// read them before the database is ready (previews, tests); every change
/// is written straight through to the attached `AppSettings` row.
@Observable
final class SettingsStore {
    private(set) var metronomeSound: MetronomeSound = .click
    private(set) var hapticEnabled = false
    private(set) var defaultBpm = PracticeConfiguration.standard.bpm
    private(set) var defaultBeatsPerChord = PracticeConfiguration.standard.beatsPerChord
    private(set) var showChordDiagram = false

    @ObservationIgnored private var record: AppSettings?

    func attach(_ record: AppSettings) {
        self.record = record
        metronomeSound = record.metronomeSound
        hapticEnabled = record.hapticEnabled
        defaultBpm = record.defaultBpm
        defaultBeatsPerChord = record.defaultBeatsPerChord
        showChordDiagram = record.showChordDiagram
    }

    func selectMetronomeSound(_ sound: MetronomeSound) {
        metronomeSound = sound
        record?.metronomeSound = sound
    }

    func toggleHaptic() {
        hapticEnabled.toggle()
        record?.hapticEnabled = hapticEnabled
    }

    func toggleShowChordDiagram() {
        showChordDiagram.toggle()
        record?.showChordDiagram = showChordDiagram
    }

    func changeDefaultBpm(by delta: Int) {
        defaultBpm = (defaultBpm + delta).clamped(to: PracticeConfiguration.bpmRange)
        record?.defaultBpm = defaultBpm
    }

    func changeDefaultBeatsPerChord(by delta: Int) {
        defaultBeatsPerChord = (defaultBeatsPerChord + delta)
            .clamped(to: PracticeConfiguration.beatsPerChordRange)
        record?.defaultBeatsPerChord = defaultBeatsPerChord
    }
}
