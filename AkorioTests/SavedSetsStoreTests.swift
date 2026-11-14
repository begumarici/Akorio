import SwiftData
import Testing
@testable import Akorio

@MainActor
struct SavedSetsStoreTests {
    private func makeStore() throws -> (SavedSetsStore, ModelContext) {
        let container = try ModelContainer(
            for: SavedChordSet.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let store = SavedSetsStore()
        store.attach(context)
        return (store, context)
    }

    private func count(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<SavedChordSet>())
    }

    @Test("Saving stores the chords, options and a trimmed name")
    func saveStoresSet() throws {
        let (store, context) = try makeStore()
        let configuration = PracticeConfiguration(bpm: 100, beatsPerChord: 2)

        let saved = store.save(name: "  Warm up  ", chordLabels: ["Am", "C"], configuration: configuration)

        #expect(saved?.name == "Warm up")
        #expect(saved?.chordLabels == ["Am", "C"])
        #expect(saved?.configuration == configuration)
        #expect(try count(in: context) == 1)
    }

    @Test("A blank name falls back to the default name")
    func blankNameFallsBack() throws {
        let (store, _) = try makeStore()

        let saved = store.save(name: "   ", chordLabels: ["G"], configuration: .standard)

        #expect(saved?.name.isEmpty == false)
    }

    @Test("Renaming trims the name and ignores blank input")
    func renameSet() throws {
        let (store, _) = try makeStore()
        let saved = try #require(store.save(name: "Old", chordLabels: ["G"], configuration: .standard))

        store.rename(saved, to: "  New  ")
        #expect(saved.name == "New")

        store.rename(saved, to: "   ")
        #expect(saved.name == "New")
    }

    @Test("Deleting removes the set")
    func deleteSet() throws {
        let (store, context) = try makeStore()
        let saved = try #require(store.save(name: "A", chordLabels: ["G"], configuration: .standard))

        store.delete(saved)

        #expect(try count(in: context) == 0)
    }
}
