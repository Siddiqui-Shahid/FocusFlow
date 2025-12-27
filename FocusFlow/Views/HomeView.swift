import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var presetStore: PresetStore
    // @EnvironmentObject var analyticsService: SessionAnalyticsService
    @State private var noteText: String = ""
    @State private var selectedPresetID: UUID?
    @State private var showPresetSheet = false
    @State private var showAnalyticsSheet = false
    @StateObject private var homeVM = HomeViewModel()

    private var selectedPreset: PresetViewData? {
        if let id = selectedPresetID {
            return presetStore.presets.first(where: { $0.id == id }) ?? presetStore.presets.first
        }
        return presetStore.presets.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color(UIColor.systemGray6).ignoresSafeArea()

                    VStack(spacing: 0) {
                        HStack {
                            // Optional title when running (driven by `showingRunningTitle` so we can fade out, swap, fade in)
                            if homeVM.showingRunningTitle {
                                VStack(spacing: 6) {
                                    Text("Deep Work")
                                        .font(.system(size: 40, weight: .heavy))
                                        .foregroundStyle(.primary)
                                }
                                .transition(.opacity)
                            } else {
                                // Top bar
                                Text("FocusFlow")
                                    .font(.largeTitle.weight(.bold))

                                Spacer()

                                HStack(spacing: 16) {
                                    Button(action: { showAnalyticsSheet = true }) {
                                        Image(systemName: "chart.bar.fill")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityLabel("Analytics")
                                    
                                    Button(action: { showPresetSheet = true }) {
                                        Image(systemName: "rectangle.stack.badge.plus")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityLabel("Manage presets")
                                }
                            }
                        }
                        .padding([.top, .horizontal])
                        .frame(height: geo.size.height * 0.1)
                        .opacity(homeVM.topBarOpacity)

                        Spacer()

                        // Timer circle
                        TimerCircleView()

                        // Controls area (single central play/pause that animates)
                        TimerControlsView(noteText: $noteText,
                                          selectedPreset: selectedPreset,
                                          startFocusAction: startFocus,
                                          startBreakAction: startBreak,
                                          stopAction: stopWithNotes)

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
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if selectedPresetID == nil {
                selectedPresetID = presetStore.presets.first?.id
            }
            // bind HomeViewModel to TimerViewModel so it can observe running state
            homeVM.bind(to: timerVM)
        }
        .onChange(of: presetStore.presets) { _, newValue in
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
        // .sheet(isPresented: $showAnalyticsSheet) {
        //     AnalyticsView(analyticsService: analyticsService)
        // }
        .onAppear {
            // Refresh analytics when view appears
            // analyticsService.refreshAllStats()
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
    
    private func stopWithNotes() {
        let notes = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        timerVM.stop(notes: notes.isEmpty ? nil : notes)
        noteText = "" // Clear notes after stopping
        
        // Refresh analytics after stopping a session
        // Task {
        //     await MainActor.run {
        //         analyticsService.refreshAllStats()
        //     }
        // }
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
