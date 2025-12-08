import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(UIColor.systemGray6).ignoresSafeArea()

                VStack {
                    HStack {
                        // Optional title when running
                        if timerVM.isRunning {
                          
                                VStack(spacing: 6) {
                                    Text("Deep Work")
                                        .font(.system(size: 40, weight: .heavy))
                                        .foregroundStyle(.primary)
                                    
                                    Text("POMODORO STRATEGY")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .tracking(2)
                                }
                            
                            .padding([.top, .horizontal])
                            .transition(.opacity)
                        } else {
                            // Top bar
                            
                            Text("FocusFlow")
                                .font(.largeTitle.weight(.bold))
                            
                            Spacer()
                            
                            Button(action: { /* open settings */ }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                }
                            
                        }
                    }
                    .padding([.top, .horizontal])
                    .offset(y: timerVM.isRunning ? -36 : 0)
                    .animation(.easeInOut(duration: 0.4), value: timerVM.isRunning)
                    Spacer()
                        // Timer circle
                        TimerCircleView()

                    // Controls area (single central play/pause that animates)
                    TimerControlsView(noteText: $noteText,
                                      start25: start25,
                                      startShortBreak: startShortBreak,
                                      startLongBreak: startLongBreak)

                    Spacer()

                    // Bottom card - hide by translating off the bottom when session is running
                    BottomCardView(start25: start25, startShortBreak: startShortBreak, startLongBreak: startLongBreak)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .offset(y: timerVM.isRunning ? 500 : 0)
                        .animation(.easeInOut(duration: 0.45), value: timerVM.isRunning)
                }
                // previously we animated the whole stack; removed so the timer circle stays fixed
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews
    // MARK: - Actions
    private func start25() { timerVM.startPreset(seconds: 25 * 60) }
    private func startShortBreak() { timerVM.startPreset(seconds: 5 * 60) }
    private func startLongBreak() { timerVM.startPreset(seconds: 15 * 60) }
}

// MARK: - Helpers Views
// MARK: - Preview

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.shared
        let vm = TimerViewModel(timerEngine: TimerEngine(), persistence: persistence)
        HomeView()
            .environmentObject(vm)
            .environment(\.managedObjectContext, persistence.viewContext)
    }
}
#endif
