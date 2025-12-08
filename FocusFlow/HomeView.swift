import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var noteText: String = ""

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(UIColor.systemGray6).ignoresSafeArea()

                VStack {
                    HStack {
                        // Optional title when running
                        if timerVM.isRunning {
                          
                                VStack(spacing: 6) {
                                    Text("Deep Work")
                                        .font(.system(size: 40, weight: .heavy))
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    Text("POMODORO STRATEGY")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(Color(UIColor.systemGray3))
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
                                    .foregroundColor(Color(UIColor.darkGray))
                            }
                            
                        }
                    }
                    .padding([.top, .horizontal])
                    .offset(y: timerVM.isRunning ? -36 : 0)
                    .animation(.easeInOut(duration: 0.4), value: timerVM.isRunning)
                    Spacer()
                    // Timer circle
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.systemGray5), lineWidth: 18)
                            .frame(width: 300, height: 300)

                        Circle()
                            .trim(from: 0, to: CGFloat(timerVM.progress))
                            .stroke(Color(.systemBlue), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 300, height: 300)
                            .animation(.easeOut(duration: 0.6), value: timerVM.progress)

                        VStack(spacing: 8) {
                            Text(timerVM.remainingTimeFormatted)
                                .font(.system(size: 72, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(Color(UIColor.label))

                            Text(timerVM.modeTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(UIColor.systemGray))
                                .tracking(1.5)
                        }
                        .animation(.easeInOut(duration: 0.25), value: timerVM.displayedState)
                    }

                    // Controls area (single central play/pause that animates)
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
                            // left control or placeholder
                            if timerVM.isRunning {
                                Button(action: { withAnimation { timerVM.stop() } }) {
                                    Circle()
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(width: 64, height: 64)
                                        .overlay(Image(systemName: "stop.fill").foregroundColor(.primary))
                                }
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                // keep placeholder so central button stays centered
                                Color.clear.frame(width: 64, height: 64)
                            }

                            // central button (always present) with animated icon crossfade
                            Button(action: handleMainButton) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: timerVM.isRunning ? 88 : 72, height: timerVM.isRunning ? 88 : 72)
                                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                                    // Stack both icons and animate opacity/scale so they appear to morph in place
                                    ZStack {
                                        Image(systemName: "play.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(Color(UIColor.label))
                                            .opacity(timerVM.isRunning ? 0 : 1)
                                            .scaleEffect(timerVM.isRunning ? 0.8 : 1)

                                        Image(systemName: "pause.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(Color(UIColor.label))
                                            .opacity(timerVM.isRunning ? 1 : 0)
                                            .scaleEffect(timerVM.isRunning ? 1 : 0.8)
                                    }
                                    .animation(.easeInOut(duration: 0.22), value: timerVM.isRunning)
                                }
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: timerVM.isRunning)
                            }

                            // right control or placeholder
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

                    Spacer()

                    // Bottom card - hide by translating off the bottom when session is running
                    bottomCard
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

    private var bottomCard: some View {
        VStack(spacing: 18) {
            // presets row
            HStack(spacing: 12) {
                CapsuleButton(title: "Pomodoro 25m", action: { start25() }, filled: true)
                CapsuleButton(title: "Short Break 5m", action: { startShortBreak() }, filled: false)
                CapsuleButton(title: "Long Break 15m", action: { startLongBreak() }, filled: false)
            }

            HStack(spacing: 12) {
                statCard(title: "Today", value: "45m", icon: "chart.bar.fill", color: Color(.systemBlue))
                statCard(title: "Streak", value: "3 Days", icon: "flame.fill", color: Color(.systemOrange))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray))
                Text(value)
                    .font(.headline).fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Actions

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

    private func start25() { timerVM.startPreset(seconds: 25 * 60) }
    private func startShortBreak() { timerVM.startPreset(seconds: 5 * 60) }
    private func startLongBreak() { timerVM.startPreset(seconds: 15 * 60) }
}

// MARK: - Helpers Views

struct CapsuleButton: View {
    let title: String
    let action: () -> Void
    var filled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(filled ? Color(.systemBlue) : Color.white)
                .foregroundColor(filled ? Color.white : Color(UIColor.darkGray))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.systemGray4), lineWidth: filled ? 0 : 1)
                )
                .cornerRadius(20)
        }
    }
}

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
