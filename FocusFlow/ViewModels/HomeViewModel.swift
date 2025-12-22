import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var topBarOpacity: Double = 1.0
    @Published var showingRunningTitle: Bool = false

    private var timerVM: TimerViewModel?
    private var observeTask: Task<Void, Never>?

    init() {}

    func bind(to timerVM: TimerViewModel) {
        // Guard against re-binding to the same timer to prevent creating duplicate observation tasks
        guard self.timerVM !== timerVM else {
            return
        }
        
        self.timerVM = timerVM
        showingRunningTitle = timerVM.isRunning
        topBarOpacity = 1.0

        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self = self else { return }
            for await state in timerVM.$displayedState.values {
                let isRunning: Bool
                switch state {
                case .running:
                    isRunning = true
                default:
                    isRunning = false
                }
                // Debug log to help diagnose frequent updates
                #if DEBUG
                print("[HomeViewModel] observed TimerViewModel.displayedState -> \(state) (isRunning=\(isRunning))")
                #endif

                // Only act when the running flag actually changes to avoid animating on every tick
                if isRunning == self.showingRunningTitle {
                    #if DEBUG
                    print("[HomeViewModel] isRunning == showingRunningTitle (\(isRunning)) — skipping animation")
                    #endif
                    continue
                }

                await self.handleRunningChanged(newValue: isRunning)
            }
        }
    }

    private func handleRunningChanged(newValue: Bool) async {
        #if DEBUG
        print("[HomeViewModel] handleRunningChanged start -> newValue=\(newValue) at \(Date())")
        #endif

        // Fade out quickly
        withAnimation(.easeOut(duration: 0.18)) {
            topBarOpacity = 0.0
        }

        // wait for fade-out to complete
        do {
            try await Task.sleep(nanoseconds: UInt64(0.18 * 1_000_000_000))
        } catch is CancellationError {
            // If the task was cancelled mid-animation, stop further UI updates.
            return
        } catch {
            // Task.sleep is not expected to throw other errors; bail out defensively.
            return
        }

        // swap and fade in slowly
        showingRunningTitle = newValue
        #if DEBUG
        print("[HomeViewModel] swapped showingRunningTitle -> \(showingRunningTitle) at \(Date())")
        #endif
        withAnimation(.easeIn(duration: 0.6)) {
            topBarOpacity = 1.0
        }

        #if DEBUG
        print("[HomeViewModel] handleRunningChanged end -> topBarOpacity=\(topBarOpacity) at \(Date())")
        #endif
    }

    deinit {
        observeTask?.cancel()
    }
}
