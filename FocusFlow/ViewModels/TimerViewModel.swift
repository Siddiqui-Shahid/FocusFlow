import Foundation
import SwiftUI
import CoreData

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var displayedState: TimerState = .idle
    @Published var currentSessionMode: SessionMode = .work
    @Published var currentJottedNotes: String = ""
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
                    
                    let previousState = self?.displayedState
                    self?.displayedState = state
                    
                    // Handle session completion when timer naturally finishes
                    if case .finished = state,
                       case .running = previousState {
                        Task {
                            let jottedNotes = self?.currentJottedNotes
                            await self?.handleSessionCompletion(jottedNotes: jottedNotes)
                        }
                    }
                }
            }
        }
    }

    // UI actions
    func start(preset: PresetViewData, mode: SessionMode, title: String? = nil) {
        Task {
            let duration = mode == .work ? preset.workDuration : preset.breakDuration
            guard duration > 0 else { return }

            // Update current session mode
            await MainActor.run {
                currentSessionMode = mode
            }

            let engine = timerEngine
            await engine.start(plannedDuration: duration)
            
            // Schedule notification for session completion
            await notificationService.scheduleSessionCompletionNotification(
                duration: duration,
                sessionType: mode.rawValue
            )

            // Use "Work" or "Break" if no custom title provided
            let sessionTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false 
                ? title 
                : (mode == .work ? "Work" : "Break")

            let ctx = persistence.newBackgroundContext()
            await ctx.perform {
                let _ = FocusSession.create(in: ctx,
                                            startTime: Date(),
                                            plannedDuration: duration,
                                            type: mode.rawValue,
                                            title: sessionTitle,
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
                                await self.notificationService.scheduleSessionCompletionNotification(
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

    func stop(jottedNotes: String? = nil) {
        Task {
            let engine = timerEngine
            let currentState = await engine.getState()
            print("Code 0098: TimerViewModel.stop() currentState=\(currentState)")
            await engine.stop()
            
            // Only cancel notifications if manually stopped (not naturally completed)
            if case .finished = currentState {
                // Timer completed naturally - don't cancel notification
                print("[TimerViewModel] Timer completed naturally - keeping notification")
            } else {
                // Timer was manually stopped - cancel notification
                await notificationService.cancelAllNotifications()
            }
            
            // Update the latest session with completion status and jotted notes as title
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
                    
                    // Update title with jotted notes if provided
                    if let jottedNotes = jottedNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !jottedNotes.isEmpty {
                        latestSession.title = jottedNotes
                        print("Code 0098: TimerViewModel.stop() updating session title to: \(jottedNotes)")
                    }
                    
                    // Debug: log what we will save for verification
                    print("Code 0098: TimerViewModel.stop() updating session id=\(latestSession.id?.uuidString ?? "nil") startTime=\(String(describing: latestSession.startTime)) plannedDuration=\(latestSession.plannedDuration) elapsedSeconds=\(latestSession.elapsedSeconds) completed=\(latestSession.completed)")
                    try? ctx.save()
                }
            }
        }
    }
    
    private func handleSessionCompletion(jottedNotes: String? = nil) async {
        print("[TimerViewModel] Session completed naturally - updating database")
        
        // Mark session as completed in database
        let ctx = persistence.newBackgroundContext()
        await ctx.perform {
            let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)]
            request.fetchLimit = 1

            if let latestSession = try? ctx.fetch(request).first {
                // For natural completion, record the full planned duration (user-selected)
                latestSession.elapsedSeconds = latestSession.plannedDuration
                latestSession.completed = true
                
                // Update title with jotted notes if provided
                if let jottedNotes = jottedNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !jottedNotes.isEmpty {
                    latestSession.title = jottedNotes
                    print("[TimerViewModel] Updated session title to: \(jottedNotes)")
                }
                
                try? ctx.save()
                print("[TimerViewModel] Marked session as completed in database id=\(latestSession.id?.uuidString ?? "nil") elapsedSeconds=\(latestSession.elapsedSeconds)")
            }
        }
    }
    
    /// Skip ahead by 30 seconds in the current session
    func skipThirtySeconds() {
        Task {
            let engine = timerEngine
            await engine.skipSeconds(30)
            // Update notification if needed
            await rescheduleNotificationForCurrentState()
        }
    }
    
    /// Skip to the end of current session (finish immediately)
    func skipToEnd(jottedNotes: String? = nil) {
        Task {
            let engine = timerEngine
            await engine.finish()
            // Cancel notification since session is finished
            await notificationService.cancelAllNotifications()
            
            // Save jotted notes as title when skipping to end
            await handleSessionCompletion(jottedNotes: jottedNotes)
        }
    }
    
    private func rescheduleNotificationForCurrentState() async {
        let currentState = await timerEngine.getState()
        
        switch currentState {
        case .running(_, let planned, let elapsed):
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
                            await self.notificationService.cancelAllNotifications()
                            await self.notificationService.scheduleSessionCompletionNotification(
                                duration: remaining,
                                sessionType: sessionType
                            )
                        }
                    }
                }
            }
        default:
            // Cancel notifications for non-running states
            await notificationService.cancelAllNotifications()
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
            return currentSessionMode == .work ? "FOCUS" : "BREAK"
        }
    }

    // Dynamic colors based on session mode
    var primaryColor: Color {
        return currentSessionMode == .work ? .blue : .orange
    }
    
    var primaryColorBackground: Color {
        return currentSessionMode == .work ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15)
    }

    // Convenience boolean for UI
    var isRunning: Bool {
        if case .running = displayedState { return true }
        return false
    }
}
