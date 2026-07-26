//
//  AppViewModel.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

enum AppScreen {
    case selector
    case practice
    case saved
    case settings
}

@Observable
final class AppViewModel {
    var screen: AppScreen = .selector

    // MARK: - Selector
    var selectedRoot: String?
    var showMoreTypes = false
    var chords: [ChordItem] = []

    // MARK: - Practice settings (live, editable; seeded from AppSettings defaults)
    var bpm = 80
    var beatsPerChord = 4
    var orderMode: OrderMode = .sequential
    var orderPickerOpen = false
    var countInEnabled = true
    var metronomeSoundEnabled = true

    // MARK: - Save dialog
    var saveDialogOpen = false
    var saveNameInput = ""

    // MARK: - Settings (mirrors the AppSettings row)
    var metronomeSound: MetronomeSound = .click
    var hapticEnabled = false
    var defaultBpm = 80
    var defaultBeatsPerChord = 4
    var soundPickerOpen = false

    private var modelContext: ModelContext?
    private var settingsRecord: AppSettings?

    // MARK: - Setup
    func configure(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        loadSettings()
    }

    private func loadSettings() {
        guard let modelContext else { return }
        if let existing = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first {
            settingsRecord = existing
        } else {
            let created = AppSettings()
            modelContext.insert(created)
            settingsRecord = created
        }
        applySettingsToState()
    }

    private func applySettingsToState() {
        guard let settingsRecord else { return }
        metronomeSound = settingsRecord.metronomeSound
        hapticEnabled = settingsRecord.hapticEnabled
        defaultBpm = settingsRecord.defaultBpm
        defaultBeatsPerChord = settingsRecord.defaultBeatsPerChord
        bpm = settingsRecord.defaultBpm
        beatsPerChord = settingsRecord.defaultBeatsPerChord
    }

    private func persistSettings() {
        guard let settingsRecord else { return }
        settingsRecord.metronomeSound = metronomeSound
        settingsRecord.hapticEnabled = hapticEnabled
        settingsRecord.defaultBpm = defaultBpm
        settingsRecord.defaultBeatsPerChord = defaultBeatsPerChord
    }

    // MARK: - Navigation
    func goToSettings() { screen = .settings }
    func goToSelectorFromSettings() { screen = .selector }
    func goToSaved() { screen = .saved }
    func goToSelectorFromSaved() { screen = .selector }
    func goToPractice() { screen = .practice }
    func goToSelector() { screen = .selector }

    // MARK: - Root note / chord type selection
    func selectRoot(_ note: String) {
        selectedRoot = note
        showMoreTypes = false
    }

    func toggleType(_ type: ChordType) {
        guard let root = selectedRoot else { return }
        let label = root + type.suffix
        if let index = chords.firstIndex(where: { $0.label == label }) {
            chords.remove(at: index)
        } else {
            chords.append(ChordItem(label: label))
        }
    }

    func removeChord(_ label: String) {
        chords.removeAll { $0.label == label }
    }

    func moveChords(from source: IndexSet, to destination: Int) {
        chords.move(fromOffsets: source, toOffset: destination)
    }

    func toggleMoreTypes() {
        showMoreTypes.toggle()
    }

    // MARK: - Practice setting adjustments
    private func clampBpm(_ value: Int) -> Int { max(40, min(240, value)) }
    private func clampBeats(_ value: Int) -> Int { max(1, min(8, value)) }

    func incBpm() { bpm = clampBpm(bpm + 1) }
    func decBpm() { bpm = clampBpm(bpm - 1) }
    func incBeats() { beatsPerChord = clampBeats(beatsPerChord + 1) }
    func decBeats() { beatsPerChord = clampBeats(beatsPerChord - 1) }

    func toggleOrderPicker() { orderPickerOpen.toggle() }
    func selectOrderMode(_ mode: OrderMode) {
        orderMode = mode
        orderPickerOpen = false
    }
    func toggleCountIn() { countInEnabled.toggle() }
    func toggleMetronomeSoundEnabled() { metronomeSoundEnabled.toggle() }

    // MARK: - Settings screen actions
    func toggleSoundPicker() { soundPickerOpen.toggle() }

    func selectMetronomeSound(_ sound: MetronomeSound) {
        metronomeSound = sound
        soundPickerOpen = false
        persistSettings()
    }

    func toggleHaptic() {
        hapticEnabled.toggle()
        persistSettings()
    }

    func incDefaultBpm() { defaultBpm = clampBpm(defaultBpm + 1); persistSettings() }
    func decDefaultBpm() { defaultBpm = clampBpm(defaultBpm - 1); persistSettings() }
    func incDefaultBeats() { defaultBeatsPerChord = clampBeats(defaultBeatsPerChord + 1); persistSettings() }
    func decDefaultBeats() { defaultBeatsPerChord = clampBeats(defaultBeatsPerChord - 1); persistSettings() }

    // MARK: - Saved sets
    func openSaveDialog() {
        var count = 0
        if let modelContext, let fetched = try? modelContext.fetchCount(FetchDescriptor<SavedChordSet>()) {
            count = fetched
        }
        saveNameInput = "Akor Seti \(count + 1)"
        saveDialogOpen = true
    }

    func closeSaveDialog() {
        saveDialogOpen = false
    }

    func confirmSave() {
        guard let modelContext else { return }
        let trimmedName = saveNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let newSet = SavedChordSet(
            name: trimmedName.isEmpty ? "Akor Seti" : trimmedName,
            chordLabels: chords.map { $0.label },
            bpm: bpm,
            beatsPerChord: beatsPerChord,
            orderMode: orderMode,
            countInEnabled: countInEnabled,
            metronomeSoundEnabled: metronomeSoundEnabled
        )
        modelContext.insert(newSet)
        saveDialogOpen = false
    }

    func loadSavedSet(_ savedSet: SavedChordSet) {
        chords = savedSet.chordLabels.map { ChordItem(label: $0) }
        bpm = savedSet.bpm
        beatsPerChord = savedSet.beatsPerChord
        orderMode = savedSet.orderMode
        countInEnabled = savedSet.countInEnabled
        metronomeSoundEnabled = savedSet.metronomeSoundEnabled
        screen = .selector
    }

    func deleteSavedSet(_ savedSet: SavedChordSet) {
        modelContext?.delete(savedSet)
    }

    func renameSavedSet(_ savedSet: SavedChordSet, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        savedSet.name = trimmed
    }
}
