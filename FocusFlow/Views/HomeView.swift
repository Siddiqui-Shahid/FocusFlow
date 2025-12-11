import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var presetStore: PresetStore
    @State private var noteText: String = ""
    @State private var selectedPresetID: UUID?
    @State private var showPresetSheet = false

    private var selectedPreset: PresetViewData? {
        if let id = selectedPresetID {
            return presetStore.presets.first(where: { $0.id == id }) ?? presetStore.presets.first
        }
        return presetStore.presets.first
    }

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
                            
                            Button(action: { showPresetSheet = true }) {
                                Image(systemName: "rectangle.stack.badge.plus")
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
                                      selectedPreset: selectedPreset,
                                      startFocusAction: startFocus,
                                      startBreakAction: startBreak)

                    Spacer()

                    // Bottom card - hide by translating off the bottom when session is running
                    BottomCardView(presets: presetStore.presets,
                                   selectedPresetID: selectedPreset?.id,
                                   onSelect: { preset in selectedPresetID = preset.id },
                                   onStartFocus: { timerVM.start(preset: $0, mode: .work) },
                                   onStartBreak: { timerVM.start(preset: $0, mode: .breakTime) },
                                   onManageTap: { showPresetSheet = true })
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .offset(y: timerVM.isRunning ? 500 : 0)
                        .animation(.easeInOut(duration: 0.45), value: timerVM.isRunning)
                }
                // previously we animated the whole stack; removed so the timer circle stays fixed
            }
            .navigationBarHidden(true)
            .onAppear {
                if selectedPresetID == nil {
                    selectedPresetID = presetStore.presets.first?.id
                }
            }
            .onChange(of: presetStore.presets) { newValue in
                guard let first = newValue.first else {
                    selectedPresetID = nil
                    return
                }
                if selectedPreset == nil {
                    selectedPresetID = first.id
                }
            }
            .sheet(isPresented: $showPresetSheet) {
                PresetManagementView()
                    .environmentObject(presetStore)
            }
        }
    }

    // MARK: - Subviews
    // MARK: - Actions
    private func startFocus() {
        guard let preset = selectedPreset else { return }
        timerVM.start(preset: preset, mode: .work)
    }

    private func startBreak() {
        guard let preset = selectedPreset else { return }
        timerVM.start(preset: preset, mode: .breakTime)
    }
}

// MARK: - Helpers Views
// MARK: - Preview

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.shared
        let vm = TimerViewModel(timerEngine: TimerEngine(), persistence: persistence)
        let presetStore = PresetStore(persistence: persistence)
        HomeView()
            .environmentObject(vm)
            .environmentObject(presetStore)
            .environment(\.managedObjectContext, persistence.viewContext)
    }
}
#endif
