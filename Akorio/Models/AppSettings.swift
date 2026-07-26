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

    init(
        metronomeSound: MetronomeSound = .click,
        hapticEnabled: Bool = false,
        defaultBpm: Int = 80,
        defaultBeatsPerChord: Int = 4
    ) {
        self.metronomeSoundRaw = metronomeSound.rawValue
        self.hapticEnabled = hapticEnabled
        self.defaultBpm = defaultBpm
        self.defaultBeatsPerChord = defaultBeatsPerChord
    }

    var metronomeSound: MetronomeSound {
        get { MetronomeSound(rawValue: metronomeSoundRaw) ?? .click }
        set { metronomeSoundRaw = newValue.rawValue }
    }
}
