//
//  AnalysisGate.swift
//  Akorio
//

import os

/// Lets one piece of work run at a time and turns away the rest. The tuner
/// uses it to drop incoming audio while an analysis is still running; it is
/// checked on the audio thread and released on the main thread, so the flag
/// is guarded by a lock.
final class AnalysisGate: Sendable {
    private let isBusy = OSAllocatedUnfairLock(initialState: false)

    /// Returns true if the caller now holds the gate, false if it is taken.
    func tryEnter() -> Bool {
        isBusy.withLock { busy in
            guard !busy else { return false }
            busy = true
            return true
        }
    }

    func leave() {
        isBusy.withLock { $0 = false }
    }
}
