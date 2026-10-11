//
//  AppViewModel.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

enum AppScreen: Hashable {
    case saved
    case practiceHistory
    case settings
    case levelDetail(ChordLevel)
}

enum AppTab: Hashable {
    case home
    case library
    case tuner
}

struct PracticeSessionSummary: Hashable {
    let durationSeconds: Int
    let chordTransitionCount: Int
    let bpm: Int
    let beatsPerChord: Int
    let chordLabels: [String]
}

@Observable
final class AppViewModel {
    var selectedTab: AppTab = .home

    /// The Selector screen is always the root; pushed screens live here.
    /// Bound directly to a `NavigationStack(path:)`, so pop (including the
    /// edge-swipe-back gesture) is handled natively.
    ///
    /// Cleanup lives here (not in a navigation function) because the native
    /// swipe-back gesture mutates `path` directly — it never calls our
    /// methods, so any "reset when returning home" logic has to react to
    /// `path` itself, not to how it changed.
    var path: [AppScreen] = [] {
        didSet {
            if path.isEmpty && !oldValue.isEmpty {
                metronome.stop()
                chords = []
                bpm = defaultBpm
                beatsPerChord = defaultBeatsPerChord
                isPracticePaused = false
                currentPracticeSummary = nil
            }
        }
    }

    // MARK: - Selector
    var chords: [ChordItem] = []

    // MARK: - Practice settings (live, editable; seeded from AppSettings defaults)
    var bpm = 80
    var beatsPerChord = 4
    var preventBackToBackRepeat = true
    var countInEnabled = true
    var metronomeSoundEnabled = true
    var currentPracticeSummary: PracticeSessionSummary?
    var isPracticePaused = false
    var isPracticePresented = false
    var showPracticeExitAlert = false
    var shouldRequestReview = false

    // MARK: - Save dialog
    var saveDialogOpen = false
    var saveNameInput = ""

    // MARK: - Settings (mirrors the AppSettings row)
    var metronomeSound: MetronomeSound = .click
    var hapticEnabled = false
    var defaultBpm = 80
    var defaultBeatsPerChord = 4
    var showChordDiagram = false
    var soundPickerOpen = false

    // MARK: - Last practice session (for the "continue" card on Home)
    var lastPracticeChordLabels: [String] = []
    var lastPracticeBpm = 80

    /// The real-time practice session (timer, count-in, click sounds).
    /// Kept as its own `@Observable` engine — see MetronomeEngine.swift.
    let metronome = MetronomeEngine()

    private var modelContext: ModelContext?
    private var settingsRecord: AppSettings?

    init() {
        metronome.configurationProvider = { [weak self] in
            guard let self else {
                return MetronomeEngine.Configuration(
                    chordLabels: [], bpm: 80, beatsPerChord: 4, preventBackToBackRepeat: true,
                    countInEnabled: true, metronomeSoundEnabled: true, metronomeSound: .click, hapticEnabled: false
                )
            }
            return MetronomeEngine.Configuration(
                chordLabels: self.chords.map { $0.label },
                bpm: self.bpm,
                beatsPerChord: self.beatsPerChord,
                preventBackToBackRepeat: self.preventBackToBackRepeat,
                countInEnabled: self.countInEnabled,
                metronomeSoundEnabled: self.metronomeSoundEnabled,
                metronomeSound: self.metronomeSound,
                hapticEnabled: self.hapticEnabled
            )
        }
    }

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
        showChordDiagram = settingsRecord.showChordDiagram
        bpm = settingsRecord.defaultBpm
        beatsPerChord = settingsRecord.defaultBeatsPerChord
        lastPracticeChordLabels = settingsRecord.lastPracticeChordLabels
        lastPracticeBpm = settingsRecord.lastPracticeBpm
    }

    private func persistSettings() {
        guard let settingsRecord else { return }
        settingsRecord.metronomeSound = metronomeSound
        settingsRecord.hapticEnabled = hapticEnabled
        settingsRecord.showChordDiagram = showChordDiagram
        settingsRecord.defaultBpm = defaultBpm
        settingsRecord.defaultBeatsPerChord = defaultBeatsPerChord
    }

    func persistLastPracticeSession() {
        guard let settingsRecord, !chords.isEmpty else { return }
        settingsRecord.lastPracticeChordLabels = chords.map { $0.label }
        settingsRecord.lastPracticeBpm = bpm
        settingsRecord.lastPracticeBeatsPerChord = beatsPerChord
        settingsRecord.lastPracticePreventBackToBackRepeat = preventBackToBackRepeat
        settingsRecord.lastPracticeCountInEnabled = countInEnabled
        settingsRecord.lastPracticeMetronomeSoundEnabled = metronomeSoundEnabled
        lastPracticeChordLabels = chords.map { $0.label }
        lastPracticeBpm = bpm
    }

    // MARK: - Navigation
    func goToSettings() { path.append(.settings) }
    func goToSaved() { path.append(.saved) }
    func goToPracticeHistory() { path.append(.practiceHistory) }
    func goToLevelDetail(_ level: ChordLevel) { path.append(.levelDetail(level)) }

    func goToPractice() {
        metronome.stop()
        isPracticePaused = false
        currentPracticeSummary = nil
        showPracticeExitAlert = false
        persistLastPracticeSession()
        isPracticePresented = true
    }

    /// Pops one screen — used by every back button. Mirrors the swipe-back
    /// gesture (one step at a time) instead of jumping straight to Home.
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func requestPracticeExit() {
        let shouldConfirmExit =
            metronome.isPlaying ||
            isPracticePaused ||
            metronome.hasStartedPractice

        guard shouldConfirmExit else {
            closePracticeFlow()
            return
        }

        if metronome.isPlaying {
            metronome.pause()
        }

        isPracticePaused = metronome.hasStartedPractice
        showPracticeExitAlert = true
    }

    func cancelPracticeExit() {
        showPracticeExitAlert = false
    }

    func confirmPracticeExit() {
        closePracticeFlow()
    }

    private func closePracticeFlow() {
        metronome.stop()
        persistLastPracticeSession()

        isPracticePaused = false
        currentPracticeSummary = nil
        showPracticeExitAlert = false
        isPracticePresented = false
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
    private func clampBpm(_ value: Int) -> Int { max(40, min(240, value)) }
    private func clampBeats(_ value: Int) -> Int { max(1, min(8, value)) }

    func incBpm() { bpm = clampBpm(bpm + 1); persistLastPracticeSession() }
    func decBpm() { bpm = clampBpm(bpm - 1); persistLastPracticeSession() }
    func incBeats() { beatsPerChord = clampBeats(beatsPerChord + 1); persistLastPracticeSession() }
    func decBeats() { beatsPerChord = clampBeats(beatsPerChord - 1); persistLastPracticeSession() }

    func toggleBackToBackRepeat() { preventBackToBackRepeat.toggle(); persistLastPracticeSession() }
    func toggleCountIn() { countInEnabled.toggle(); persistLastPracticeSession() }
    func toggleMetronomeSoundEnabled() { metronomeSoundEnabled.toggle(); persistLastPracticeSession() }
    func toggleShowChordDiagram() {
        showChordDiagram.toggle()
        persistSettings()
    }

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
        saveNameInput = String(format: String(localized: "Akor Seti %@"), "\(count + 1)")
        saveDialogOpen = true
    }

    func closeSaveDialog() {
        saveDialogOpen = false
    }

    func confirmSave() {
        guard let modelContext else { return }
        let trimmedName = saveNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let newSet = SavedChordSet(
            name: trimmedName.isEmpty ? String(localized: "Akor Seti") : trimmedName,
            chordLabels: chords.map { $0.label },
            bpm: bpm,
            beatsPerChord: beatsPerChord,
            preventBackToBackRepeat: preventBackToBackRepeat,
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
        preventBackToBackRepeat = savedSet.preventBackToBackRepeat
        countInEnabled = savedSet.countInEnabled
        metronomeSoundEnabled = savedSet.metronomeSoundEnabled
        metronome.stop()
        persistLastPracticeSession()

        isPracticePaused = false
        currentPracticeSummary = nil
        showPracticeExitAlert = false
        isPracticePresented = true
    }

    var hasLastPracticeSession: Bool { !lastPracticeChordLabels.isEmpty }

    var lastPracticeSubtitle: String {
        "\(lastPracticeChordLabels.joined(separator: ", ")) · \(lastPracticeBpm) BPM"
    }

    func continueLastPractice() {
        guard let settingsRecord else { return }
        chords = settingsRecord.lastPracticeChordLabels.map { ChordItem(label: $0) }
        bpm = settingsRecord.lastPracticeBpm
        beatsPerChord = settingsRecord.lastPracticeBeatsPerChord
        preventBackToBackRepeat = settingsRecord.lastPracticePreventBackToBackRepeat
        countInEnabled = settingsRecord.lastPracticeCountInEnabled
        metronomeSoundEnabled = settingsRecord.lastPracticeMetronomeSoundEnabled
        metronome.stop()

        isPracticePaused = false
        currentPracticeSummary = nil
        showPracticeExitAlert = false
        isPracticePresented = true
    }

    func deleteSavedSet(_ savedSet: SavedChordSet) {
        modelContext?.delete(savedSet)
    }

    func renameSavedSet(_ savedSet: SavedChordSet, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        savedSet.name = trimmed
    }

    // MARK: - Metronome passthrough
    var isPlaying: Bool { metronome.isPlaying }
    var isCountingIn: Bool { metronome.isCountingIn }
    var countInBeatsLeft: Int { metronome.countInBeatsLeft }
    var currentChordLabel: String { metronome.currentChordLabel }
    var nextChordLabel: String { metronome.nextChordLabel }
    var beatInCurrentChord: Int { metronome.beatInCurrentChord }

    func togglePlay() {
        if metronome.isPlaying {
            pausePracticeSession()
        } else {
            currentPracticeSummary = nil
            isPracticePaused = false
            metronome.toggle()
        }
    }

    func pausePracticeSession() {
        if metronome.isCountingIn && !metronome.hasStartedPractice {
            metronome.stop()
            isPracticePaused = false
            return
        }
        metronome.pause()
        isPracticePaused = true
    }

    func resumePracticeSession() {
        metronome.resume()
        isPracticePaused = false
    }

    func finishPracticeSession() {
        let durationSeconds = metronome.elapsedPracticeSeconds
        let transitionCount = metronome.chordTransitionCount

        metronome.stop()
        isPracticePaused = false

        guard durationSeconds > 0 else { return }

        let summary = PracticeSessionSummary(
            durationSeconds: durationSeconds,
            chordTransitionCount: transitionCount,
            bpm: bpm,
            beatsPerChord: beatsPerChord,
            chordLabels: chords.map(\.label)
        )

        saveCompletedPracticeSession(summary)
        currentPracticeSummary = summary
    }

    private func saveCompletedPracticeSession(_ summary: PracticeSessionSummary) {
        guard let modelContext else { return }

        let session = PracticeSession(
            durationSeconds: summary.durationSeconds,
            chordTransitionCount: summary.chordTransitionCount,
            bpm: summary.bpm,
            beatsPerChord: summary.beatsPerChord,
            chordLabels: summary.chordLabels
        )

        modelContext.insert(session)
        try? modelContext.save()
    }

    func repeatPracticeSession() {
        currentPracticeSummary = nil
        isPracticePaused = false
    }

    func returnHomeFromPracticeSummary() {
        metronome.stop()
        currentPracticeSummary = nil
        isPracticePaused = false
        showPracticeExitAlert = false
        isPracticePresented = false

        selectedTab = .home
        path = []

        chords = []
        bpm = defaultBpm
        beatsPerChord = defaultBeatsPerChord

        scheduleReviewRequestIfEligible()
    }

    private func scheduleReviewRequestIfEligible() {
        guard let modelContext, let settingsRecord else { return }
        guard let completedSessionCount = try? modelContext.fetchCount(FetchDescriptor<PracticeSession>()) else {
            return
        }
        guard ReviewRequestPolicy.isEligible(
            completedSessionCount: completedSessionCount,
            hasRequestedReview: settingsRecord.hasRequestedAppStoreReview
        ) else {
            return
        }

        shouldRequestReview = true
    }

    func appStoreReviewRequestWasHandled() {
        shouldRequestReview = false
        settingsRecord?.hasRequestedAppStoreReview = true
        try? modelContext?.save()
    }
}
