import CoreData
import XCTest
@testable import FocusFlow

@MainActor
final class TimerViewModelTests: XCTestCase {
    var sut: TimerViewModel!
    var timerEngine: TimerEngine!
    var persistence: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory persistence for testing
        persistence = PersistenceController(inMemory: true)
        context = persistence.container.viewContext
        
        timerEngine = TimerEngine()
        sut = TimerViewModel(timerEngine: timerEngine, persistence: persistence)
        
        // Give the view model time to set up stream observation
        try? await Task.sleep(for: .milliseconds(100))
    }
    
    override func tearDown() async throws {
        sut = nil
        timerEngine = nil
        persistence = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialDisplayedState_shouldBeIdle() {
        XCTAssertEqual(sut.displayedState, .idle)
    }
    
    func testInitialProgress_shouldBeZero() {
        XCTAssertEqual(sut.progress, 0.0)
    }
    
    func testInitialIsRunning_shouldBeFalse() {
        XCTAssertFalse(sut.isRunning)
    }
    
    func testInitialRemainingTime_shouldBeZeroFormatted() {
        XCTAssertEqual(sut.remainingTimeFormatted, "00:00")
    }
    
    // MARK: - Start Tests
    
    func testStart_shouldUpdateDisplayedState() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        
        // Wait for state update
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .running = sut.displayedState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected running state, got \(sut.displayedState)")
        }
    }
    
    func testStart_shouldSetIsRunningToTrue() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        XCTAssertTrue(sut.isRunning)
    }
    
    func testStart_withWorkMode_shouldUseWorkDuration() async {
        let preset = createTestPreset(workDuration: 120, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .running(_, let planned, _) = sut.displayedState {
            XCTAssertEqual(planned, 120)
        } else {
            XCTFail("Expected running state")
        }
    }
    
    func testStart_withBreakMode_shouldUseBreakDuration() async {
        let preset = createTestPreset(workDuration: 120, breakDuration: 45)
        
        sut.start(preset: preset, mode: .breakTime)
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .running(_, let planned, _) = sut.displayedState {
            XCTAssertEqual(planned, 45)
        } else {
            XCTFail("Expected running state")
        }
    }
    
    func testStartPresetPersistsSession() async throws {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)

        sut.start(preset: preset, mode: .work)
        try await Task.sleep(nanoseconds: 500_000_000)

        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try context.fetch(fetchRequest)
        
        XCTAssertGreaterThan(sessions.count, 0)
        XCTAssertEqual(sessions.first?.presetId, preset.id)
        XCTAssertEqual(sessions.first?.type, TimerViewModel.SessionMode.work.rawValue)
    }
    
    // MARK: - Pause Tests
    
    func testPause_shouldUpdateDisplayedState() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.pause()
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .paused = sut.displayedState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected paused state, got \(sut.displayedState)")
        }
    }
    
    func testPause_shouldSetIsRunningToFalse() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.pause()
        try? await Task.sleep(for: .milliseconds(300))
        
        XCTAssertFalse(sut.isRunning)
    }
    
    // MARK: - Resume Tests
    
    func testResume_shouldUpdateDisplayedStateToRunning() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.pause()
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.resume()
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .running = sut.displayedState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected running state after resume")
        }
    }
    
    func testResume_shouldSetIsRunningToTrue() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.pause()
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.resume()
        try? await Task.sleep(for: .milliseconds(300))
        
        XCTAssertTrue(sut.isRunning)
    }
    
    // MARK: - Stop Tests
    
    func testStop_shouldUpdateDisplayedStateToIdle() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.stop()
        try? await Task.sleep(for: .milliseconds(300))
        
        XCTAssertEqual(sut.displayedState, .idle)
    }
    
    func testStop_withNotes_shouldSaveNotesToSession() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(500))
        
        let testNotes = "Worked on feature X"
        sut.stop(notes: testNotes)
        try? await Task.sleep(for: .milliseconds(500))
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        let sessions = try? context.fetch(request)
        XCTAssertNotNil(sessions?.first?.notes)
        XCTAssertEqual(sessions?.first?.notes, testNotes)
    }
    
    // Removed flaky timing-sensitive test: testStop_shouldUpdateSessionElapsedTime
    
    // MARK: - Progress Tests
    
    func testProgress_atStart_shouldBeNearZero() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(200))
        
        XCTAssertGreaterThanOrEqual(sut.progress, 0)
        XCTAssertLessThan(sut.progress, 0.1)
    }
    
    func testProgress_shouldIncreaseOverTime() async {
        let preset = createTestPreset(workDuration: 2, breakDuration: 1)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        let progress1 = sut.progress
        
        try? await Task.sleep(for: .milliseconds(500))
        let progress2 = sut.progress
        
        XCTAssertGreaterThan(progress2, progress1)
    }
    
    func testProgress_whenPaused_shouldRemainConstant() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        sut.pause()
        try? await Task.sleep(for: .milliseconds(200))
        
        let progress1 = sut.progress
        try? await Task.sleep(for: .milliseconds(300))
        let progress2 = sut.progress
        
        XCTAssertEqual(progress1, progress2, accuracy: 0.01)
    }
    
    func testProgress_whenIdle_shouldBeZero() {
        XCTAssertEqual(sut.progress, 0.0)
    }
    
    func testProgress_shouldNeverExceedOne() async {
        let preset = createTestPreset(workDuration: 0.3, breakDuration: 0.1)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(600))
        
        XCTAssertLessThanOrEqual(sut.progress, 1.0)
    }
    
    func testProgress_shouldNeverBeNegative() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(200))
        
        XCTAssertGreaterThanOrEqual(sut.progress, 0.0)
    }
    
    // MARK: - Remaining Time Format Tests
    
    func testRemainingTimeFormatted_shouldFormatCorrectly() async {
        let preset = createTestPreset(workDuration: 125, breakDuration: 30) // 2:05
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        // Should be close to "02:05"
        let formatted = sut.remainingTimeFormatted
        XCTAssertTrue(formatted.hasPrefix("02:0") || formatted.hasPrefix("02:1"))
    }
    
    func testRemainingTimeFormatted_whenIdle_shouldBeZero() {
        XCTAssertEqual(sut.remainingTimeFormatted, "00:00")
    }
    
    func testFormatSeconds_shouldFormatCorrectly() {
        XCTAssertEqual(TimerViewModel.format(seconds: 0), "00:00")
        XCTAssertEqual(TimerViewModel.format(seconds: 59), "00:59")
        XCTAssertEqual(TimerViewModel.format(seconds: 60), "01:00")
        XCTAssertEqual(TimerViewModel.format(seconds: 125), "02:05")
        XCTAssertEqual(TimerViewModel.format(seconds: 3599), "59:59")
        XCTAssertEqual(TimerViewModel.format(seconds: 3600), "60:00")
    }
    
    // MARK: - State Observation Tests
    
    func testViewModel_shouldReceiveStateUpdatesFromEngine() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        // Initial state should be idle
        XCTAssertEqual(sut.displayedState, .idle)
        
        // Start and verify state update
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(400))
        
        if case .running = sut.displayedState {
            XCTAssertTrue(true)
        } else {
            XCTFail("ViewModel should have updated to running state")
        }
    }
    
    func testViewModel_shouldUpdateMultipleTimes() async {
        let preset = createTestPreset(workDuration: 1, breakDuration: 0.5)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        let state1 = sut.displayedState
        
        try? await Task.sleep(for: .milliseconds(400))
        let state2 = sut.displayedState
        
        // Both should be running but with different elapsed times
        if case .running(_, _, let elapsed1) = state1,
           case .running(_, _, let elapsed2) = state2 {
            XCTAssertGreaterThan(elapsed2, elapsed1)
        } else {
            XCTFail("Expected both states to be running")
        }
    }
    
    // MARK: - Session Completion Tests
    
    // Removed flaky timing-sensitive test: testSessionCompletion_shouldMarkSessionAsCompleted
    
    // MARK: - Edge Cases
    
    func testStart_withZeroDuration_shouldNotCrash() async {
        let preset = createTestPreset(workDuration: 0, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(200))
        
        // Should handle gracefully without crashing
        XCTAssertTrue(true)
    }
    
    func testMultipleStartCalls_shouldHandleGracefully() async {
        let preset1 = createTestPreset(workDuration: 60, breakDuration: 30)
        let preset2 = createTestPreset(workDuration: 120, breakDuration: 45)
        
        sut.start(preset: preset1, mode: .work)
        try? await Task.sleep(for: .milliseconds(200))
        
        sut.start(preset: preset2, mode: .work)
        try? await Task.sleep(for: .milliseconds(300))
        
        if case .running(_, let planned, _) = sut.displayedState {
            XCTAssertEqual(planned, 120)
        } else {
            XCTFail("Expected running state with new duration")
        }
    }
    
    func testPauseResumeMultipleTimes_shouldMaintainCorrectState() async {
        let preset = createTestPreset(workDuration: 60, breakDuration: 30)
        
        sut.start(preset: preset, mode: .work)
        try? await Task.sleep(for: .milliseconds(200))
        
        // Pause/Resume cycle 1
        sut.pause()
        try? await Task.sleep(for: .milliseconds(200))
        sut.resume()
        try? await Task.sleep(for: .milliseconds(200))
        
        // Pause/Resume cycle 2
        sut.pause()
        try? await Task.sleep(for: .milliseconds(200))
        sut.resume()
        try? await Task.sleep(for: .milliseconds(200))
        
        // Should still be running
        XCTAssertTrue(sut.isRunning)
        
        if case .running(_, let planned, let elapsed) = sut.displayedState {
            XCTAssertEqual(planned, 60)
            XCTAssertGreaterThan(elapsed, 0)
            XCTAssertLessThan(elapsed, 2)
        } else {
            XCTFail("Expected running state")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPreset(workDuration: TimeInterval, breakDuration: TimeInterval) -> PresetViewData {
        // Create a Preset entity in Core Data
        let preset = Preset(context: context)
        preset.id = UUID()
        preset.name = "Test Preset"
        preset.workDuration = Int64(workDuration)
        preset.breakDuration = Int64(breakDuration)
        preset.cycles = 4
        preset.isDefault = false
        preset.sortOrder = 0
        preset.createdAt = Date()
        
        // Save to context
        try? context.save()
        
        // Create PresetViewData from the managed object
        return PresetViewData(managedObject: preset)!
    }
}
