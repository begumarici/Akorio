//
//  AppViewModel.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

@Observable
final class AppViewModel {
    let router = AppRouter()

    // MARK: - Selector
    var chords: [ChordItem] = []

    // MARK: - Practice settings (live, editable; seeded from AppSettings defaults)
    /// Changed only through `updatePractice(_:)`, which also remembers the
    /// session for the "continue" card.
    private(set) var practice = PracticeConfiguration.standard

    // MARK: - Stores
    let settings = SettingsStore()
    let savedSets = SavedSetsStore()
    let session = PracticeSessionController()

    // MARK: - Last practice session (for the "continue" card on Home)
    var lastPracticeChordLabels: [String] = []
    var lastPracticeBpm = PracticeConfiguration.standard.bpm

    private var modelContext: ModelContext?
    private var settingsRecord: AppSettings?

    init() {
        session.metronome.configurationProvider = { [weak self] in
            guard let self else { return MetronomeEngine.Configuration() }
            return MetronomeEngine.Configuration(
                chordLabels: self.chords.map(\.label),
                practice: self.practice,
                metronomeSound: self.settings.metronomeSound,
                hapticEnabled: self.settings.hapticEnabled
            )
        }
        session.planProvider = { [weak self] in
            guard let self else { return PracticeSessionController.Plan() }
            return .init(chordLabels: self.chords.map(\.label), configuration: self.practice)
        }
        session.willClose = { [weak self] in
            self?.persistLastPracticeSession()
        }
        router.onReturnedHome = { [weak self] in
            guard let self else { return }
            session.reset()
            resetPracticeForNewSession()
        }
    }

    // MARK: - Setup
    func configure(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        savedSets.attach(context)

        let record = AppSettings.fetchOrCreate(in: context)
        settingsRecord = record
        settings.attach(record)
        session.attach(context: context, settings: record)

        practice.bpm = settings.defaultBpm
        practice.beatsPerChord = settings.defaultBeatsPerChord
        lastPracticeChordLabels = record.lastPracticeChordLabels
        lastPracticeBpm = record.lastPracticeBpm
    }

    func persistLastPracticeSession() {
        guard let settingsRecord, !chords.isEmpty else { return }
        settingsRecord.lastPracticeChordLabels = chords.map(\.label)
        settingsRecord.lastPracticeConfiguration = practice
        lastPracticeChordLabels = chords.map(\.label)
        lastPracticeBpm = practice.bpm
    }

    // MARK: - Practice flow
    func goToPractice() {
        session.reset()
        persistLastPracticeSession()
        router.goToPracticePlan()
    }

    func startPracticeFromPlan() {
        persistLastPracticeSession()
        session.isPresented = true
    }

    func cancelPracticePlan() {
        session.reset()
        router.popPracticePlan()
    }

    func returnHomeFromPracticeSummary() {
        session.finishSummary()
        router.goHome()
        resetPracticeForNewSession()
        session.requestReviewIfEligible()
    }

    // MARK: - Chord selection
    func toggleChordLabel(_ label: String) {
        if let index = chords.firstIndex(where: { $0.label == label }) {
            chords.remove(at: index)
        } else {
            chords.append(ChordItem(label: label))
        }
    }

    func selectAllChordLabels(_ labels: [String]) {
        for label in labels where !chords.contains(where: { $0.label == label }) {
            chords.append(ChordItem(label: label))
        }
    }

    func deselectAllChordLabels(_ labels: [String]) {
        chords.removeAll { labels.contains($0.label) }
    }

    // MARK: - Practice setting adjustments
    func updatePractice(_ change: (inout PracticeConfiguration) -> Void) {
        let previousGoal = practice.durationGoal
        change(&practice)
        persistLastPracticeSession()
        if practice.durationGoal != previousGoal {
            session.metronome.refreshDurationGoal()
        }
    }

    private func resetPracticeForNewSession() {
        chords = []
        practice.resetForNewSession(
            defaultBPM: settings.defaultBpm,
            defaultBeatsPerChord: settings.defaultBeatsPerChord
        )
    }

    // MARK: - Saved sets
    func saveCurrentSet(named name: String) {
        savedSets.save(name: name, chordLabels: chords.map(\.label), configuration: practice)
    }

    func loadSavedSet(_ savedSet: SavedChordSet) {
        chords = savedSet.chordLabels.map { ChordItem(label: $0) }
        practice = savedSet.configuration
        persistLastPracticeSession()
        session.start()
    }

    var hasLastPracticeSession: Bool { !lastPracticeChordLabels.isEmpty }

    var lastPracticeSubtitle: String {
        "\(lastPracticeChordLabels.joined(separator: ", ")) · \(lastPracticeBpm) BPM"
    }

    func continueLastPractice() {
        guard let settingsRecord else { return }
        chords = settingsRecord.lastPracticeChordLabels.map { ChordItem(label: $0) }
        practice = settingsRecord.lastPracticeConfiguration
        session.start()
    }
}
