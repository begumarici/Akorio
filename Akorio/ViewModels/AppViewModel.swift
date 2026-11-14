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
    case practicePlan
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
    let targetDurationMinutes: Int?
    let goalCompleted: Bool
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
                isPracticePaused = false
                currentPracticeSummary = nil
                resetPracticeForNewSession()
            }
        }
    }

    // MARK: - Selector
    var chords: [ChordItem] = []

    // MARK: - Practice settings (live, editable; seeded from AppSettings defaults)
    /// Changed only through `updatePractice(_:)`, which also remembers the
    /// session for the "continue" card.
    private(set) var practice = PracticeConfiguration.standard
    var currentPracticeSummary: PracticeSessionSummary?
    var isPracticePaused = false
    var isPracticePresented = false
    var showPracticeExitAlert = false
    var shouldRequestReview = false

    // MARK: - Save dialog
    var saveDialogOpen = false
    var saveNameInput = ""

    // MARK: - Settings
    let settings = SettingsStore()

    // MARK: - Last practice session (for the "continue" card on Home)
    var lastPracticeChordLabels: [String] = []
    var lastPracticeBpm = PracticeConfiguration.standard.bpm

    /// The real-time practice session (timer, count-in, click sounds).
    /// Kept as its own `@Observable` engine — see MetronomeEngine.swift.
    let metronome = MetronomeEngine()

    private var modelContext: ModelContext?
    private var settingsRecord: AppSettings?

    init() {
        metronome.configurationProvider = { [weak self] in
            guard let self else { return MetronomeEngine.Configuration() }
            return MetronomeEngine.Configuration(
                chordLabels: self.chords.map(\.label),
                practice: self.practice,
                metronomeSound: self.settings.metronomeSound,
                hapticEnabled: self.settings.hapticEnabled
            )
        }
        metronome.goalReachedHandler = { [weak self] in
            self?.finishPracticeSession(goalReached: true)
        }
    }

    // MARK: - Setup
    func configure(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context

        let record = AppSettings.fetchOrCreate(in: context)
        settingsRecord = record
        settings.attach(record)

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
        path.append(.practicePlan)
    }

    func startPracticeFromPlan() {
        persistLastPracticeSession()
        isPracticePresented = true
    }

    func cancelPracticePlan() {
        metronome.stop()
        isPracticePaused = false
        currentPracticeSummary = nil
        showPracticeExitAlert = false
        if path.last == .practicePlan {
            path.removeLast()
        }
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
    func updatePractice(_ change: (inout PracticeConfiguration) -> Void) {
        let previousGoal = practice.durationGoal
        change(&practice)
        persistLastPracticeSession()
        if practice.durationGoal != previousGoal {
            metronome.refreshDurationGoal()
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
            chordLabels: chords.map(\.label),
            configuration: practice
        )
        modelContext.insert(newSet)
        saveDialogOpen = false
    }

    func loadSavedSet(_ savedSet: SavedChordSet) {
        chords = savedSet.chordLabels.map { ChordItem(label: $0) }
        practice = savedSet.configuration
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
        practice = settingsRecord.lastPracticeConfiguration
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
    var elapsedPracticeSeconds: Int { metronome.elapsedPracticeSeconds }
    var remainingPracticeSeconds: Int? {
        PracticeGoalCalculator.remainingSeconds(
            elapsedSeconds: metronome.elapsedPracticeSeconds,
            goal: practice.durationGoal
        )
    }

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

    func finishPracticeSession(goalReached: Bool = false) {
        let elapsedSeconds = metronome.elapsedPracticeSeconds
        let durationSeconds = PracticeGoalCalculator.recordedDurationSeconds(
            elapsedSeconds: elapsedSeconds,
            goal: practice.durationGoal,
            goalReached: goalReached
        )
        let transitionCount = metronome.chordTransitionCount

        metronome.stop()
        isPracticePaused = false

        guard durationSeconds > 0 else { return }

        let summary = PracticeSessionSummary(
            durationSeconds: durationSeconds,
            chordTransitionCount: transitionCount,
            bpm: practice.bpm,
            beatsPerChord: practice.beatsPerChord,
            chordLabels: chords.map(\.label),
            targetDurationMinutes: practice.durationGoal.minutes,
            goalCompleted: goalReached || PracticeGoalCalculator.isCompleted(
                elapsedSeconds: elapsedSeconds,
                goal: practice.durationGoal
            )
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
            chordLabels: summary.chordLabels,
            targetDurationMinutes: summary.targetDurationMinutes,
            goalCompleted: summary.goalCompleted
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
        resetPracticeForNewSession()

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
