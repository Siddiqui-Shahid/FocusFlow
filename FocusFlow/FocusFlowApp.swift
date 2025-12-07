import SwiftUI

@main
struct FocusFlowApp: App {
    // Shared services
    let persistence = PersistenceController.shared
    @StateObject var timerVM = TimerViewModel(timerEngine: TimerEngine(), persistence: PersistenceController.shared)

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(timerVM)
        }
    }
}
