//
//  AppSettings.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var metronomeSoundRaw: String
    var hapticEnabled: Bool
    var defaultBpm: Int
    var defaultBeatsPerChord: Int
    // Defaulted so SwiftData can lightweight-migrate existing rows when
    // this attribute is added to the schema (see SavedChordSet for why).
    var showChordDiagram: Bool = false

    init(
        metronomeSound: MetronomeSound = .click,
        hapticEnabled: Bool = false,
        defaultBpm: Int = 80,
        defaultBeatsPerChord: Int = 4,
        showChordDiagram: Bool = false
    ) {
        self.metronomeSoundRaw = metronomeSound.rawValue
        self.hapticEnabled = hapticEnabled
        self.defaultBpm = defaultBpm
        self.defaultBeatsPerChord = defaultBeatsPerChord
        self.showChordDiagram = showChordDiagram
    }

    var metronomeSound: MetronomeSound {
        get { MetronomeSound(rawValue: metronomeSoundRaw) ?? .click }
        set { metronomeSoundRaw = newValue.rawValue }
    }
}
