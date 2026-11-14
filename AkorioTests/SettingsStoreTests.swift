import SwiftData
import Testing
@testable import Akorio

@MainActor
struct SettingsStoreTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test("The settings row is created once and reused")
    func fetchOrCreateReturnsSingleRow() throws {
        let context = try makeContext()

        let first = AppSettings.fetchOrCreate(in: context)
        let second = AppSettings.fetchOrCreate(in: context)

        #expect(first === second)
        #expect(try context.fetchCount(FetchDescriptor<AppSettings>()) == 1)
    }

    @Test("Attaching a row loads its saved preferences")
    func attachReadsRecord() throws {
        let context = try makeContext()
        let record = AppSettings(
            metronomeSound: .wood,
            hapticEnabled: true,
            defaultBpm: 120,
            defaultBeatsPerChord: 2,
            showChordDiagram: true
        )
        context.insert(record)

        let store = SettingsStore()
        store.attach(record)

        #expect(store.metronomeSound == .wood)
        #expect(store.hapticEnabled)
        #expect(store.defaultBpm == 120)
        #expect(store.defaultBeatsPerChord == 2)
        #expect(store.showChordDiagram)
    }

    @Test("Changes are written through to the settings row")
    func changesPersist() throws {
        let context = try makeContext()
        let record = AppSettings.fetchOrCreate(in: context)
        let store = SettingsStore()
        store.attach(record)

        store.selectMetronomeSound(.beep)
        store.toggleHaptic()
        store.toggleShowChordDiagram()
        store.changeDefaultBpm(by: 5)
        store.changeDefaultBeatsPerChord(by: -1)

        #expect(record.metronomeSound == .beep)
        #expect(record.hapticEnabled)
        #expect(record.showChordDiagram)
        #expect(record.defaultBpm == 85)
        #expect(record.defaultBeatsPerChord == 3)
    }

    @Test("Default tempo and beats stay inside their supported ranges")
    func defaultsAreClamped() {
        let store = SettingsStore()

        store.changeDefaultBpm(by: -1_000)
        store.changeDefaultBeatsPerChord(by: 1_000)

        #expect(store.defaultBpm == PracticeConfiguration.bpmRange.lowerBound)
        #expect(store.defaultBeatsPerChord == PracticeConfiguration.beatsPerChordRange.upperBound)
    }
}
