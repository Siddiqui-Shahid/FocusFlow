import SwiftUI

struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var presetStore: PresetStore
    // @EnvironmentObject var analyticsService: SessionAnalyticsService
    @State private var noteText: String = ""
    @State private var selectedPresetID: UUID?
    @State private var showPresetSheet = false
    @State private var showAnalyticsSheet = false
    @State private var showNoteSavedBanner = false
    @State private var sessionTitle: String = ""
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

                    // confirmation banner shown when a note is saved
                    noteSavedBanner()

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

                        // Session note input (appears during timer)
                        if timerVM.isRunning {
                            TextField("Aim for the session", text: $sessionTitle)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .onChange(of: sessionTitle) { _, newValue in
                                    timerVM.currentJottedNotes = newValue
                                }
                        }
                        Spacer()

                        // Bottom card - hide by translating off the bottom when session is running
                        BottomCardView(presets: presetStore.presets,
                                       selectedPresetID: selectedPreset?.id,
                                       onSelect: { preset in selectedPresetID = preset.id },
                                       onStartFocus: { timerVM.start(preset: $0, mode: .work, title: nil) },
                                       onStartBreak: { timerVM.start(preset: $0, mode: .breakTime, title: nil) },
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
        let titleToUse = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sessionTitle
        timerVM.start(preset: preset, mode: .work, title: titleToUse)
        sessionTitle = ""
    }

    private func startBreak() {
        guard let preset = selectedPreset else { return }
        let titleToUse = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sessionTitle
        timerVM.start(preset: preset, mode: .breakTime, title: titleToUse)
        sessionTitle = ""
    }
    
    private func stopWithNotes() {
        let jottedNotes = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        timerVM.stop(jottedNotes: jottedNotes.isEmpty ? nil : jottedNotes)
        sessionTitle = "" // Clear notes after stopping
        timerVM.currentJottedNotes = ""
        withAnimation {
            showNoteSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showNoteSavedBanner = false
            }
        }
        
        // Refresh analytics after stopping a session
        // Task {
        //     await MainActor.run {
        //         analyticsService.refreshAllStats()
        //     }
        // }
    }

    // Simple banner overlay for confirmation
    @ViewBuilder
    private func noteSavedBanner() -> some View {
        if showNoteSavedBanner {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("Note saved")
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.accentColor)
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(.top, 44)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
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
