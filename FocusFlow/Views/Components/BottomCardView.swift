import SwiftUI

struct BottomCardView: View {
    let presets: [PresetViewData]
    let selectedPresetID: UUID?
    var onSelect: (PresetViewData) -> Void
    var onStartFocus: (PresetViewData) -> Void
    var onStartBreak: (PresetViewData) -> Void
    var onManageTap: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets) { preset in
                        PresetTileView(preset: preset,
                                       isSelected: preset.id == selectedPresetID,
                                       onSelect: { onSelect(preset) },
                                       onStartFocus: { onStartFocus(preset) },
                                       onStartBreak: { onStartBreak(preset) })
                    }

                    Button(action: onManageTap) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Preset")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 140, height: 120)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(18)
                    }
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 12) {
                StatCardView(title: "Today", value: "45m", icon: "chart.bar.fill", color: Color(.systemBlue))
                
                NavigationLink(destination: SessionHistoryView().environment(\.managedObjectContext, PersistenceController.shared.viewContext)) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("History")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("View All")
                                .font(.headline).fontWeight(.bold)
                                .foregroundColor(.primary)
                        }

                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

private struct PresetTileView: View {
    let preset: PresetViewData
    let isSelected: Bool
    var onSelect: () -> Void
    var onStartFocus: () -> Void
    var onStartBreak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                Text(preset.displayTitle)
                    .font(.headline)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Text("Focus \(minutesString(for: preset.workDuration)) · Break \(minutesString(for: preset.breakDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                CapsuleButton(title: "Focus", action: onStartFocus, filled: true)
                CapsuleButton(title: "Break", action: onStartBreak, filled: false)
            }
        }
        .padding()
        .frame(width: 220, alignment: .leading)
        .background(isSelected ? Color(UIColor.systemGray5) : Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .onTapGesture(perform: onSelect)
    }

    private func minutesString(for seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    }
}

#if DEBUG
struct BottomCardView_Previews: PreviewProvider {
    static var previews: some View {
        let p = PersistenceController.shared
        let presetStore = PresetStore(persistence: p)
        BottomCardView(presets: presetStore.presets,
                   selectedPresetID: presetStore.presets.first?.id,
                   onSelect: { _ in },
                   onStartFocus: { _ in },
                   onStartBreak: { _ in },
                   onManageTap: {})
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
