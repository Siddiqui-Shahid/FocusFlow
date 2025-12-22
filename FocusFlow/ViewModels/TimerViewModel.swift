import Foundation
import SwiftUI
import CoreData

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var displayedState: TimerState = .idle
    private let timerEngine: TimerEngine
    private var streamTask: Task<Void, Never>?
    let persistence: PersistenceController
    private let notificationService = NotificationService.shared

    enum SessionMode: String {
        case work
        case breakTime = "break"
    }

    init(timerEngine: TimerEngine, persistence: PersistenceController) {
        self.timerEngine = timerEngine
        self.persistence = persistence
        observeEngine()
    }

    func observeEngine() {
        streamTask?.cancel()
        // Capture the engine in a local constant to avoid implicit property capture
        let engine = timerEngine
        streamTask = Task { [weak self] in
            for await state in await engine.stream {
                await MainActor.run {
                    #if DEBUG
                    print("[TimerViewModel] engine emitted state -> \(state) at \(Date())")
                    #endif
                    self?.displayedState = state
                }
            }
        }
    }

    // UI actions
    func start(preset: PresetViewData, mode: SessionMode) {
        Task {
            let duration = mode == .work ? preset.workDuration : preset.breakDuration
            guard duration > 0 else { return }

            let engine = timerEngine
            await engine.start(plannedDuration: duration)
            
            // Schedule notification for session completion
            await notificationService.scheduleSessionCompletionNotification(
                duration: duration,
                sessionType: mode.rawValue
            )

            let ctx = persistence.newBackgroundContext()
            await ctx.perform {
                let _ = FocusSession.create(in: ctx,
                                            startTime: Date(),
                                            plannedDuration: duration,
                                            type: mode.rawValue,
                                            presetId: preset.id)
                try? ctx.save()
            }
        }
    }

    func pause() {
        Task {
            let engine = timerEngine
            await engine.pause()
            // Cancel notification when paused
            await notificationService.cancelAllNotifications()
        }
    }

    func resume() {
        Task {
            let engine = timerEngine
            let currentState = await engine.getState()
            await engine.resume()
            
            // Reschedule notification for remaining time
            if case .paused(let elapsed, let planned) = currentState {
                let remaining = max(0, planned - elapsed)
                if remaining > 0 {
                    // Determine session type from current session
                    let ctx = persistence.newBackgroundContext()
                    await ctx.perform {
                        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
                        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)]
                        request.fetchLimit = 1
                        
                        if let latestSession = try? ctx.fetch(request).first,
                           let sessionType = latestSession.type {
                            Task {
                                await notificationService.scheduleSessionCompletionNotification(
                                    duration: remaining,
                                    sessionType: sessionType
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    func stop(notes: String? = nil) {
        Task {
            let engine = timerEngine
            let currentState = await engine.getState()
            await engine.stop()
            
            // Cancel any pending notifications
            await notificationService.cancelAllNotifications()
            
            // Update the latest session with completion status and notes
            let ctx = persistence.newBackgroundContext()
            await ctx.perform {
                let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)]
                request.fetchLimit = 1
                
                if let latestSession = try? ctx.fetch(request).first {
                    // Calculate elapsed time from current state
                    switch currentState {
                    case .running(_, _, let elapsed), .paused(let elapsed, _):
                        latestSession.markCompleted(elapsedTime: elapsed)
                    case .finished:
                        latestSession.completed = true
                    default:
                        break
                    }
                    
                    // Save notes if provided
                    if let notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                        latestSession.notes = notes
                    }
                    
                    try? ctx.save()
                }
            }
        }
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

    // Progress between 0.0 and 1.0 for UI ring (0 = none, 1 = finished)
    var progress: Double {
        switch displayedState {
        case .idle:
            return 0
        case .finished:
            return 1
        case .running(_, let planned, let elapsed):
            guard planned > 0 else { return 0 }
            return min(1, max(0, elapsed / planned))
        case .paused(let elapsed, let planned):
            guard planned > 0 else { return 0 }
            return min(1, max(0, elapsed / planned))
        }
    }

    // Simple human-facing mode title (e.g. "FOCUS" / "BREAK") - can be extended
    var modeTitle: String {
        switch displayedState {
        case .idle, .finished:
            return "FOCUS"
        case .running, .paused:
            return "FOCUS"
        }
    }

    // Convenience boolean for UI
    var isRunning: Bool {
        if case .running = displayedState { return true }
        return false
    }
}
