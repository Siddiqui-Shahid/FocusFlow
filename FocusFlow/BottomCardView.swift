import SwiftUI

struct BottomCardView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    var start25: () -> Void
    var startShortBreak: () -> Void
    var startLongBreak: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            // presets row
            HStack(spacing: 12) {
                CapsuleButton(title: "Pomodoro 25m", action: start25, filled: true)
                CapsuleButton(title: "Short Break 5m", action: startShortBreak, filled: false)
                CapsuleButton(title: "Long Break 15m", action: startLongBreak, filled: false)
            }

            HStack(spacing: 12) {
                StatCardView(title: "Today", value: "45m", icon: "chart.bar.fill", color: Color(.systemBlue))
                StatCardView(title: "Streak", value: "3 Days", icon: "flame.fill", color: Color(.systemOrange))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#if DEBUG
struct BottomCardView_Previews: PreviewProvider {
    static var previews: some View {
        let p = PersistenceController.shared
        let vm = TimerViewModel(timerEngine: TimerEngine(), persistence: p)
        BottomCardView(start25: {}, startShortBreak: {}, startLongBreak: {})
            .environmentObject(vm)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
