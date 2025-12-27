import XCTest
@testable import FocusFlow

@MainActor
final class TimerEngineTests: XCTestCase {
    var sut: TimerEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = TimerEngine()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_shouldBeIdle() async {
        let state = await sut.getState()
        XCTAssertEqual(state, .idle)
    }
    
    func testInitialRemaining_shouldBeZero() async {
        let remaining = await sut.remaining()
        XCTAssertEqual(remaining, 0)
    }
    
    // MARK: - Start Tests
    
    func testStart_shouldTransitionToRunning() async {
        await sut.start(plannedDuration: 60)
        let state = await sut.getState()
        
        if case .running(let startTime, let planned, let elapsed) = state {
            XCTAssertEqual(planned, 60, accuracy: 0.01)
            XCTAssertEqual(elapsed, 0, accuracy: 0.5) // Allow small elapsed due to execution time
            XCTAssertNotNil(startTime)
        } else {
            XCTFail("Expected running state, got \(state)")
        }
    }
    
    func testStart_shouldSetCorrectPlannedDuration() async {
        let testDuration: TimeInterval = 120
        await sut.start(plannedDuration: testDuration)
        let state = await sut.getState()
        
        if case .running(_, let planned, _) = state {
            XCTAssertEqual(planned, testDuration)
        } else {
            XCTFail("Expected running state")
        }
    }
    
    func testStart_shouldHaveNearlyFullRemaining() async {
        await sut.start(plannedDuration: 100)
        let remaining = await sut.remaining()
        
        // Should be close to 100, accounting for execution time
        XCTAssertGreaterThan(remaining, 99)
        XCTAssertLessThanOrEqual(remaining, 100)
    }
    
    // MARK: - Pause Tests
    
    func testPause_fromRunningState_shouldTransitionToPaused() async {
        await sut.start(plannedDuration: 60)
        
        // Wait a bit to accumulate some elapsed time
        try? await Task.sleep(for: .milliseconds(500))
        
        await sut.pause()
        let state = await sut.getState()
        
        if case .paused(let elapsed, let planned) = state {
            XCTAssertEqual(planned, 60)
            XCTAssertGreaterThan(elapsed, 0)
            XCTAssertLessThan(elapsed, 2) // Should be less than 2 seconds
        } else {
            XCTFail("Expected paused state, got \(state)")
        }
    }
    
    func testPause_fromIdleState_shouldRemainIdle() async {
        await sut.pause()
        let state = await sut.getState()
        XCTAssertEqual(state, .idle)
    }
    
    func testPause_shouldPreserveElapsedTime() async {
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(500))
        
        await sut.pause()
        let pausedState = await sut.getState()
        
        if case .paused(let elapsed, _) = pausedState {
            // Elapsed should be approximately 0.5 seconds
            XCTAssertGreaterThan(elapsed, 0.4)
            XCTAssertLessThan(elapsed, 1.0)
        } else {
            XCTFail("Expected paused state")
        }
    }
    
    func testPause_shouldCalculateCorrectRemaining() async {
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(500))
        
        await sut.pause()
        let remaining = await sut.remaining()
        
        // Should be approximately 59.5 seconds
        XCTAssertGreaterThan(remaining, 58)
        XCTAssertLessThan(remaining, 60)
    }
    
    // MARK: - Resume Tests
    
    func testResume_fromPausedState_shouldTransitionToRunning() async {
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(300))
        await sut.pause()
        
        let pausedState = await sut.getState()
        guard case .paused(let pausedElapsed, _) = pausedState else {
            XCTFail("Expected paused state")
            return
        }
        
        await sut.resume()
        let runningState = await sut.getState()
        
        if case .running(_, let planned, let elapsed) = runningState {
            XCTAssertEqual(planned, 60)
            // Elapsed should be approximately same as when paused
            XCTAssertEqual(elapsed, pausedElapsed, accuracy: 0.1)
        } else {
            XCTFail("Expected running state after resume")
        }
    }
    
    func testResume_fromIdleState_shouldRemainIdle() async {
        await sut.resume()
        let state = await sut.getState()
        XCTAssertEqual(state, .idle)
    }
    
    func testResume_shouldContinueFromPausedElapsed() async {
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(300))
        
        await sut.pause()
        let pausedState = await sut.getState()
        guard case .paused(let pausedElapsed, _) = pausedState else {
            XCTFail("Expected paused state")
            return
        }
        
        await sut.resume()
        try? await Task.sleep(for: .milliseconds(300))
        
        let resumedState = await sut.getState()
        if case .running(_, _, let currentElapsed) = resumedState {
            // Current elapsed should be pausedElapsed + ~0.3s
            XCTAssertGreaterThan(currentElapsed, pausedElapsed)
            XCTAssertLessThan(currentElapsed, pausedElapsed + 1.0)
        } else {
            XCTFail("Expected running state")
        }
    }
    
    // MARK: - Stop Tests
    
    func testStop_fromRunningState_shouldTransitionToIdle() async {
        await sut.start(plannedDuration: 60)
        await sut.stop()
        
        let state = await sut.getState()
        XCTAssertEqual(state, .idle)
    }
    
    func testStop_fromPausedState_shouldTransitionToIdle() async {
        await sut.start(plannedDuration: 60)
        await sut.pause()
        await sut.stop()
        
        let state = await sut.getState()
        XCTAssertEqual(state, .idle)
    }
    
    func testStop_shouldResetRemaining() async {
        await sut.start(plannedDuration: 60)
        await sut.stop()
        
        let remaining = await sut.remaining()
        XCTAssertEqual(remaining, 0)
    }
    
    // MARK: - Completion Tests
    
    func testTimer_shouldFinishAfterPlannedDuration() async {
        // Use a very short duration for testing
        await sut.start(plannedDuration: 0.5)
        
        // Wait for timer to finish
        try? await Task.sleep(for: .milliseconds(700))
        
        let state = await sut.getState()
        XCTAssertEqual(state, .finished)
    }
    
    func testTimer_finishedRemaining_shouldBeZero() async {
        await sut.start(plannedDuration: 0.3)
        try? await Task.sleep(for: .milliseconds(500))
        
        let state = await sut.getState()
        XCTAssertEqual(state, .finished)
        
        let remaining = await sut.remaining()
        XCTAssertEqual(remaining, 0)
    }
    
    // MARK: - State Stream Tests
    
    func testStream_shouldEmitInitialState() async {
        let expectation = XCTestExpectation(description: "Should receive initial state")
        
        Task {
            var receivedState: TimerState?
            for await state in await sut.stream {
                receivedState = state
                expectation.fulfill()
                break
            }
            XCTAssertEqual(receivedState, .idle)
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testStream_shouldEmitStateChanges() async {
        let expectation = XCTestExpectation(description: "Should receive running state")
        
        Task {
            var count = 0
            for await state in await sut.stream {
                count += 1
                if case .running = state {
                    expectation.fulfill()
                    break
                }
                if count > 5 {
                    break
                }
            }
        }
        
        // Give stream time to start listening
        try? await Task.sleep(for: .milliseconds(100))
        await sut.start(plannedDuration: 60)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleStartCalls_shouldReplaceState() async {
        await sut.start(plannedDuration: 60)
        await sut.start(plannedDuration: 120)
        
        let state = await sut.getState()
        if case .running(_, let planned, _) = state {
            XCTAssertEqual(planned, 120)
        } else {
            XCTFail("Expected running state with new duration")
        }
    }
    
    func testZeroDuration_shouldHandleGracefully() async {
        await sut.start(plannedDuration: 0)
        let state = await sut.getState()
        
        // Should either be finished immediately or running with 0 planned
        switch state {
        case .running(_, let planned, _):
            XCTAssertEqual(planned, 0)
        case .finished:
            XCTAssertTrue(true) // This is also acceptable
        default:
            XCTFail("Unexpected state for zero duration")
        }
    }
    
    func testNegativeDuration_shouldHandleGracefully() async {
        await sut.start(plannedDuration: -10)
        let state = await sut.getState()
        
        // Engine should handle this - either clamp to 0 or finish immediately
        switch state {
        case .running(_, let planned, _):
            // If it allows negative, at least verify it's set
            XCTAssertEqual(planned, -10)
        case .finished:
            XCTAssertTrue(true)
        default:
            break
        }
    }
    
    func testPauseResumeCycle_shouldMaintainElapsedAccuracy() async {
        // Start timer
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(200))
        
        // Pause
        await sut.pause()
        let pausedState1 = await sut.getState()
        guard case .paused(let elapsed1, _) = pausedState1 else {
            XCTFail("Expected paused state")
            return
        }
        
        try? await Task.sleep(for: .milliseconds(200))
        
        // Resume
        await sut.resume()
        try? await Task.sleep(for: .milliseconds(200))
        
        // Pause again
        await sut.pause()
        let pausedState2 = await sut.getState()
        guard case .paused(let elapsed2, _) = pausedState2 else {
            XCTFail("Expected paused state")
            return
        }
        
        // Total elapsed should be approximately 400ms
        XCTAssertGreaterThan(elapsed2, elapsed1)
        XCTAssertGreaterThan(elapsed2, 0.3)
        XCTAssertLessThan(elapsed2, 1.0)
    }
    
    // MARK: - Remaining Calculation Tests
    
    func testRemaining_whileRunning_shouldDecreaseOverTime() async {
        await sut.start(plannedDuration: 10)
        let remaining1 = await sut.remaining()
        
        try? await Task.sleep(for: .milliseconds(500))
        let remaining2 = await sut.remaining()
        
        XCTAssertLessThan(remaining2, remaining1)
        XCTAssertGreaterThan(remaining2, 8.5)
    }
    
    func testRemaining_whilePaused_shouldStayConstant() async {
        await sut.start(plannedDuration: 60)
        try? await Task.sleep(for: .milliseconds(300))
        await sut.pause()
        
        let remaining1 = await sut.remaining()
        try? await Task.sleep(for: .milliseconds(300))
        let remaining2 = await sut.remaining()
        
        XCTAssertEqual(remaining1, remaining2, accuracy: 0.01)
    }
    
    func testRemaining_shouldNeverBeNegative() async {
        await sut.start(plannedDuration: 0.2)
        try? await Task.sleep(for: .milliseconds(500))
        
        let remaining = await sut.remaining()
        XCTAssertGreaterThanOrEqual(remaining, 0)
    }
}
