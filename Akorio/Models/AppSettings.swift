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

    // The most recently entered practice session — lets the home screen
    // offer a one-tap "continue" without the user having to re-pick chords.
    // All defaulted for the same lightweight-migration reason as above.
    var lastPracticeChordLabels: [String] = []
    var lastPracticeBpm: Int = 80
    var lastPracticeBeatsPerChord: Int = 4
    var lastPracticePreventBackToBackRepeat: Bool = true
    var lastPracticeCountInEnabled: Bool = true
    var lastPracticeMetronomeSoundEnabled: Bool = true
    var lastPracticeTargetDurationMinutes: Int? = nil
    var lastPracticeAccentFirstBeat: Bool = true
    var hasRequestedAppStoreReview: Bool = false

    init(
        metronomeSound: MetronomeSound = .click,
        hapticEnabled: Bool = false,
        defaultBpm: Int = PracticeConfiguration.standard.bpm,
        defaultBeatsPerChord: Int = PracticeConfiguration.standard.beatsPerChord,
        showChordDiagram: Bool = false
    ) {
        self.metronomeSoundRaw = metronomeSound.rawValue
        self.hapticEnabled = hapticEnabled
        self.defaultBpm = defaultBpm
        self.defaultBeatsPerChord = defaultBeatsPerChord
        self.showChordDiagram = showChordDiagram
    }

    /// The app keeps exactly one settings row; this returns it, creating it
    /// on first launch.
    static func fetchOrCreate(in context: ModelContext) -> AppSettings {
        if let existing = try? context.fetch(FetchDescriptor<AppSettings>()).first {
            return existing
        }
        let created = AppSettings()
        context.insert(created)
        return created
    }

    var metronomeSound: MetronomeSound {
        get { MetronomeSound(rawValue: metronomeSoundRaw) ?? .click }
        set { metronomeSoundRaw = newValue.rawValue }
    }

    /// The last session's options, read and written as one value. The
    /// stored columns stay flat so existing databases keep loading.
    var lastPracticeConfiguration: PracticeConfiguration {
        get {
            PracticeConfiguration(
                bpm: lastPracticeBpm,
                beatsPerChord: lastPracticeBeatsPerChord,
                preventBackToBackRepeat: lastPracticePreventBackToBackRepeat,
                countInEnabled: lastPracticeCountInEnabled,
                metronomeSoundEnabled: lastPracticeMetronomeSoundEnabled,
                durationGoal: PracticeDurationGoal(minutes: lastPracticeTargetDurationMinutes),
                accentFirstBeat: lastPracticeAccentFirstBeat
            )
        }
        set {
            lastPracticeBpm = newValue.bpm
            lastPracticeBeatsPerChord = newValue.beatsPerChord
            lastPracticePreventBackToBackRepeat = newValue.preventBackToBackRepeat
            lastPracticeCountInEnabled = newValue.countInEnabled
            lastPracticeMetronomeSoundEnabled = newValue.metronomeSoundEnabled
            lastPracticeTargetDurationMinutes = newValue.durationGoal.minutes
            lastPracticeAccentFirstBeat = newValue.accentFirstBeat
        }
    }
}
