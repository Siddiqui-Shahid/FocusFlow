import Foundation

/// Simple timer state representation
public enum TimerState: Equatable {
    case idle
    case running(startTime: Date, plannedDuration: TimeInterval, elapsed: TimeInterval)
    case paused(elapsed: TimeInterval, plannedDuration: TimeInterval)
    case finished
}

/// TimerEngine - actor to manage a single timer safely across threads.
/// Publishes updates via AsyncStream<TimerState> which the UI can subscribe to.
public actor TimerEngine {
    public private(set) var state: TimerState = .idle

    // AsyncStream / Continuation for UI updates
    private var continuation: AsyncStream<TimerState>.Continuation?
    public var stream: AsyncStream<TimerState> {
        AsyncStream { cont in
            self.continuation = cont
            cont.yield(self.state)
        }
    }

    private var tickTask: Task<Void, Never>?

    public init() {}

    public func start(plannedDuration: TimeInterval) async {
        let now = Date()
        state = .running(startTime: now, plannedDuration: plannedDuration, elapsed: 0)
        scheduleTicks()
        publishState()
        // Persist session via SessionManager (call out to persistence in ViewModel)
    }

    public func pause() async {
        switch state {
        case .running(let start, let planned, _):
            let elapsed = Date().timeIntervalSince(start)
            state = .paused(elapsed: elapsed, plannedDuration: planned)
            cancelTicks()
            publishState()
        default:
            return
        }
    }

    public func resume() async {
        switch state {
        case .paused(let elapsed, let planned):
            // To resume correctly we want the running state's "startTime" to reflect
            // that `elapsed` time has already passed. Setting startTime = Date() - elapsed
            // makes Date().timeIntervalSince(startTime) == elapsed + timeSinceResume.
            let resumedStart = Date().addingTimeInterval(-elapsed)
            state = .running(startTime: resumedStart, plannedDuration: planned, elapsed: elapsed)
            scheduleTicks()
            publishState()
        default:
            return
        }
    }

    public func stop() async {
        cancelTicks()
        state = .idle
        publishState()
    }
    
    /// Skip ahead by a specific number of seconds
    public func skipSeconds(_ seconds: TimeInterval) async {
        guard seconds > 0 else { return }
        
        switch state {
        case .running(let start, let planned, _):
            let currentElapsed = Date().timeIntervalSince(start)
            let newElapsed = min(currentElapsed + seconds, planned)
            
            if newElapsed >= planned {
                // Skip to finished
                state = .finished
                cancelTicks()
            } else {
                // Adjust start time to reflect the skipped seconds
                let newStart = Date().addingTimeInterval(-newElapsed)
                state = .running(startTime: newStart, plannedDuration: planned, elapsed: newElapsed)
            }
            publishState()
        case .paused(let elapsed, let planned):
            let newElapsed = min(elapsed + seconds, planned)
            
            if newElapsed >= planned {
                state = .finished
            } else {
                state = .paused(elapsed: newElapsed, plannedDuration: planned)
            }
            publishState()
        default:
            return
        }
    }
    
    /// Immediately finish the current session
    public func finish() async {
        switch state {
        case .running, .paused:
            state = .finished
            cancelTicks()
            publishState()
        default:
            return
        }
    }
    
    public func getState() async -> TimerState {
        return state
    }

    // compute current remaining (safe)
    public func remaining() -> TimeInterval {
        switch state {
        case .idle:
            return 0
        case .finished:
            return 0
        case .paused(let elapsed, let planned):
            return max(0, planned - elapsed)
        case .running(let start, let planned, _):
            let elapsed = Date().timeIntervalSince(start)
            return max(0, planned - elapsed)
        }
    }

    private func scheduleTicks() {
        cancelTicks()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: .milliseconds(200)) // 200ms for smooth UI
            }
        }
    }

    private func cancelTicks() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func tick() async {
        // If running and finished, move to finished state
        switch state {
        case .running(let start, let planned, _):
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= planned {
                state = .finished
                cancelTicks()
            } else {
                // keep as running but update elapsed for UI
                state = .running(startTime: start, plannedDuration: planned, elapsed: elapsed)
            }
            publishState()
        default:
            break
        }
    }

    private func publishState() {
        continuation?.yield(state)
    }
}
