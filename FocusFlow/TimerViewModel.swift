import Foundation
import SwiftUI
import CoreData

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var displayedState: TimerState = .idle
    private let timerEngine: TimerEngine
    private var streamTask: Task<Void, Never>?
    let persistence: PersistenceController

    init(timerEngine: TimerEngine, persistence: PersistenceController) {
        self.timerEngine = timerEngine
        self.persistence = persistence
        observeEngine()
    }

    func observeEngine() {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            for await state in await timerEngine.stream {
                await MainActor.run {
                    self?.displayedState = state
                }
            }
        }
    }

    // UI actions
    func startPreset(seconds: TimeInterval) {
        Task {
            await timerEngine.start(plannedDuration: seconds)
            // persist session start
            let ctx = persistence.newBackgroundContext()
            await ctx.perform {
                let _ = FocusSession.create(in: ctx, startTime: Date(), plannedDuration: seconds)
                try? ctx.save()
            }
        }
    }

    func pause() {
        Task { await timerEngine.pause() }
    }

    func resume() {
        Task { await timerEngine.resume() }
    }

    func stop() {
        Task { await timerEngine.stop() }
    }

    deinit {
        streamTask?.cancel()
    }

    // Helpers for UI
    var remainingTimeFormatted: String {
        let remaining: TimeInterval
        switch displayedState {
        case .idle:
            remaining = 0
        case .running(_, let planned, let elapsed):
            remaining = max(0, planned - elapsed)
        case .paused(let elapsed, let planned):
            remaining = max(0, planned - elapsed)
        case .finished:
            remaining = 0
        }
        return Self.format(seconds: Int(remaining))
    }

    static func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
