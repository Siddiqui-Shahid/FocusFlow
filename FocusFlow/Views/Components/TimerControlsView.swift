import SwiftUI

struct TimerControlsView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @Binding var noteText: String

    var selectedPreset: PresetViewData?
    var startFocusAction: () -> Void
    var startBreakAction: () -> Void
    var stopAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            if let preset = selectedPreset {
                Text(preset.displayTitle.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }



            HStack(spacing: 48) {
                if timerVM.isRunning {
                    Button(action: { 
                        withAnimation { 
                            stopAction?() ?? timerVM.stop()
                        } 
                    }) {
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
                    Button(action: { 
                        timerVM.skipThirtySeconds()
                    }) {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(
                                VStack(spacing: 2) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.primary)
                                    Text("30s")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            let jottedNotes = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                            timerVM.skipToEnd(jottedNotes: jottedNotes.isEmpty ? nil : jottedNotes)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: startBreakAction) {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(Image(systemName: "moon.zzz.fill").foregroundColor(.primary))
                    }
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
                startFocusAction()
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
        let presetStore = PresetStore(persistence: p)
        TimerControlsView(noteText: .constant(""),
                          selectedPreset: presetStore.presets.first,
                          startFocusAction: {},
                          startBreakAction: {},
                          stopAction: {})
            .environmentObject(vm)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
