import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("FocusFlow")
                    .font(.largeTitle.weight(.bold))

                Text(timerVM.remainingTimeFormatted)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 16) {
                    Button(action: start25) {
                        Label("Start 25m", systemImage: "play.fill")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: start5) {
                        Label("Start 5m", systemImage: "play")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                }

                actionsForState()

                Spacer()
            }
            .padding()
            .navigationTitle("Timer")
        }
    }

    @ViewBuilder
    private func actionsForState() -> some View {
        switch timerVM.displayedState {
        case .idle, .finished:
            EmptyView()
        case .running:
            HStack {
                Button("Pause") { timerVM.pause() }
                    .buttonStyle(.bordered)
                Button("Stop") { timerVM.stop() }
                    .buttonStyle(.bordered)
            }
        case .paused:
            HStack {
                Button("Resume") { timerVM.resume() }
                    .buttonStyle(.borderedProminent)
                Button("Stop") { timerVM.stop() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func start25() {
        timerVM.startPreset(seconds: 25 * 60)
    }

    private func start5() {
        timerVM.startPreset(seconds: 5 * 60)
    }
}

#if DEBUG
import SwiftUI
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
