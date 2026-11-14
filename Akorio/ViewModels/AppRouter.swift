//
//  AppRouter.swift
//  Akorio
//

import Foundation
import Observation

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

/// Which tab is selected and which screens are pushed on the Home stack.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home

    /// Bound directly to a `NavigationStack(path:)`, so pop (including the
    /// edge-swipe-back gesture) is handled natively.
    ///
    /// The "returned home" callback fires from here (not from a navigation
    /// function) because the native swipe-back gesture mutates `path`
    /// directly — it never calls our methods, so any cleanup has to react
    /// to `path` itself, not to how it changed.
    var path: [AppScreen] = [] {
        didSet {
            if path.isEmpty && !oldValue.isEmpty {
                onReturnedHome?()
            }
        }
    }

    @ObservationIgnored var onReturnedHome: (() -> Void)?

    func goToSettings() { path.append(.settings) }
    func goToSaved() { path.append(.saved) }
    func goToPracticeHistory() { path.append(.practiceHistory) }
    func goToLevelDetail(_ level: ChordLevel) { path.append(.levelDetail(level)) }
    func goToPracticePlan() { path.append(.practicePlan) }

    /// Pops one screen — used by every back button. Mirrors the swipe-back
    /// gesture (one step at a time) instead of jumping straight to Home.
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popPracticePlan() {
        if path.last == .practicePlan {
            path.removeLast()
        }
    }

    func goHome() {
        selectedTab = .home
        path = []
    }
}
