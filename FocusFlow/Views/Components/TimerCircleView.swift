import SwiftUI

struct TimerCircleView: View {
    @EnvironmentObject var timerVM: TimerViewModel

    var body: some View {
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
                    .foregroundStyle(.primary)

                Text(timerVM.modeTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
            }
            .animation(.easeInOut(duration: 0.25), value: timerVM.displayedState)
        }
    }
}

#if DEBUG
struct TimerCircleView_Previews: PreviewProvider {
    static var previews: some View {
        let p = PersistenceController.shared
        let vm = TimerViewModel(timerEngine: TimerEngine(), persistence: p)
        TimerCircleView().environmentObject(vm)
    }
}
#endif
