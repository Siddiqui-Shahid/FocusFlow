import XCTest
@testable import FocusFlow

@MainActor
final class PresetStoreTests: XCTestCase {
    func testDefaultPresetsSeeded() {
        let persistence = PersistenceController(inMemory: true)
        let store = PresetStore(persistence: persistence)
        XCTAssertFalse(store.presets.isEmpty)
    }

    func testAddPresetPersists() throws {
        let persistence = PersistenceController(inMemory: true)
        let store = PresetStore(persistence: persistence)
        let initialCount = store.presets.count
        try store.addPreset(name: "Test Focus", workDuration: 30 * 60, breakDuration: 5 * 60)
        XCTAssertEqual(store.presets.count, initialCount + 1)
        XCTAssertTrue(store.presets.contains { $0.name == "Test Focus" })
    }
}
