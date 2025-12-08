import CoreData
import XCTest
@testable import FocusFlow

@MainActor
final class TimerViewModelTests: XCTestCase {
    func testStartPresetPersistsSession() async throws {
        let persistence = PersistenceController(inMemory: true)
        let viewModel = TimerViewModel(timerEngine: TimerEngine(), persistence: persistence)
        let store = PresetStore(persistence: persistence)
        guard let preset = store.presets.first else {
            XCTFail("Expected seeded preset")
            return
        }

        viewModel.start(preset: preset, mode: .work)
        try await Task.sleep(nanoseconds: 200_000_000)

        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try persistence.viewContext.fetch(fetchRequest)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.presetId, preset.id)
        XCTAssertEqual(sessions.first?.type, TimerViewModel.SessionMode.work.rawValue)
    }
}
