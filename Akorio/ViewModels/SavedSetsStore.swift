//
//  SavedSetsStore.swift
//  Akorio
//

import Foundation
import SwiftData

/// Creates, renames and deletes saved chord sets. Screens list the sets
/// with `@Query`; this only owns the changes.
final class SavedSetsStore {
    private var context: ModelContext?

    func attach(_ context: ModelContext) {
        self.context = context
    }

    /// A default name for the next set, e.g. "Akor Seti 3".
    func suggestedName() -> String {
        let count = (try? context?.fetchCount(FetchDescriptor<SavedChordSet>())) ?? 0
        return String(format: String(localized: "Akor Seti %@"), "\(count + 1)")
    }

    @discardableResult
    func save(
        name: String,
        chordLabels: [String],
        configuration: PracticeConfiguration
    ) -> SavedChordSet? {
        guard let context else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedSet = SavedChordSet(
            name: trimmed.isEmpty ? String(localized: "Akor Seti") : trimmed,
            chordLabels: chordLabels,
            configuration: configuration
        )
        context.insert(savedSet)
        return savedSet
    }

    func rename(_ savedSet: SavedChordSet, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        savedSet.name = trimmed
    }

    func delete(_ savedSet: SavedChordSet) {
        context?.delete(savedSet)
    }
}
