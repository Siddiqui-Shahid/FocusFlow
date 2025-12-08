import SwiftUI

struct TimerControlsView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @Binding var noteText: String

    var start25: () -> Void
    var startShortBreak: () -> Void
    var startLongBreak: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if timerVM.isRunning {
                TextField("Jot down a distraction...", text: $noteText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 48) {
                if timerVM.isRunning {
                    Button(action: { withAnimation { timerVM.stop() } }) {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(Image(systemName: "stop.fill").foregroundColor(.primary))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear.frame(width: 64, height: 64)
                }

                Button(action: handleMainButton) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: timerVM.isRunning ? 88 : 72, height: timerVM.isRunning ? 88 : 72)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                        ZStack {
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.primary)
                                .opacity(timerVM.isRunning ? 0 : 1)
                                .scaleEffect(timerVM.isRunning ? 0.8 : 1)

                            Image(systemName: "pause.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.primary)
                                .opacity(timerVM.isRunning ? 1 : 0)
                                .scaleEffect(timerVM.isRunning ? 1 : 0.8)
                        }
                        .animation(.easeInOut(duration: 0.22), value: timerVM.isRunning)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: timerVM.isRunning)
                }

                if timerVM.isRunning {
                    Button(action: { /* skip to next */ }) {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(Image(systemName: "forward.fill").foregroundColor(.primary))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear.frame(width: 64, height: 64)
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 32)
        .offset(y: timerVM.isRunning ? -8 : 0)
        .animation(.easeInOut(duration: 0.28), value: timerVM.isRunning)
    }

    private func handleMainButton() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch timerVM.displayedState {
            case .idle, .finished:
                start25()
            case .running:
                timerVM.pause()
            case .paused:
                timerVM.resume()
            }
        }
    }
}

#if DEBUG
struct TimerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        let p = PersistenceController.shared
        let vm = TimerViewModel(timerEngine: TimerEngine(), persistence: p)
        TimerControlsView(noteText: .constant(""), start25: {}, startShortBreak: {}, startLongBreak: {})
            .environmentObject(vm)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
