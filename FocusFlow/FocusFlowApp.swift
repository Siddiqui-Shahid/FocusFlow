import SwiftUI

@main
struct FocusFlowApp: App {
    // Shared services
    let persistence = PersistenceController.shared
    @StateObject var timerVM = TimerViewModel(timerEngine: TimerEngine(), persistence: PersistenceController.shared)
    @StateObject var presetStore = PresetStore(persistence: PersistenceController.shared)
    // @StateObject var analyticsService = SessionAnalyticsService(context: PersistenceController.shared.viewContext)

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(timerVM)
                .environmentObject(presetStore)
                // .environmentObject(analyticsService)
                .task {
                    // Request notification permissions when app launches
                    await NotificationService.shared.requestPermission()
                }
        }
    }
}
