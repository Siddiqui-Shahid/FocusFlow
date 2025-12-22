import SwiftUI
import UIKit

struct PresetManagementView: View {
    @EnvironmentObject var presetStore: PresetStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft = PresetDraft()
    @State private var editingPreset: PresetViewData?
    @State private var showingEditor = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(presetStore.presets) { preset in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(preset.displayTitle)
                                        .font(.headline)
                                    if preset.isDefault {
                                        Text("Default")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(UIColor.systemGray5))
                                            .cornerRadius(6)
                                    }
                                }

                                Text("Focus \(minutesString(preset.workDuration)) • Break \(minutesString(preset.breakDuration))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        presentEditor(for: preset)
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            presetStore.delete(preset)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        draft = PresetDraft()
                        editingPreset = nil
                        errorMessage = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                PresetEditorView(title: editingPreset == nil ? "New Preset" : "Edit Preset",
                                 draft: $draft,
                                 errorMessage: $errorMessage,
                                 onDismiss: { showingEditor = false },
                                 onSave: saveDraft)
            }
        }
    }

    private func presentEditor(for preset: PresetViewData) {
        draft = PresetDraft(preset: preset)
        editingPreset = preset
        errorMessage = nil
        showingEditor = true
    }

    private func saveDraft() {
        do {
            let accentHex = draft.normalizedAccent
            if let editingPreset {
                try presetStore.update(preset: editingPreset,
                                       name: draft.name,
                                       workDuration: draft.workSeconds,
                                       breakDuration: draft.breakSeconds,
                                       cycles: draft.cycles,
                                       accentColorHex: accentHex)
            } else {
                try presetStore.addPreset(name: draft.name,
                                          workDuration: draft.workSeconds,
                                          breakDuration: draft.breakSeconds,
                                          cycles: draft.cycles,
                                          accentColorHex: accentHex)
            }
            showingEditor = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func minutesString(_ seconds: TimeInterval) -> String {
        "\(Int(seconds / 60))m"
    }

    private func timeAgoString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func dateTimeString(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// Local helpers to convert UIColor <-> Hex to avoid depending on external utils during build
fileprivate func uiColorFromHex(_ hex: String) -> UIColor? {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") { s.removeFirst() }
    let len = s.count
    guard len == 6 || len == 8 else { return nil }
    var hexValue: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&hexValue) else { return nil }
    var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255
    if len == 6 {
        r = (hexValue & 0xFF0000) >> 16
        g = (hexValue & 0x00FF00) >> 8
        b = (hexValue & 0x0000FF)
    } else {
        r = (hexValue & 0xFF000000) >> 24
        g = (hexValue & 0x00FF0000) >> 16
        b = (hexValue & 0x0000FF00) >> 8
        a = (hexValue & 0x000000FF)
    }
    return UIColor(red: CGFloat(r) / 255.0,
                   green: CGFloat(g) / 255.0,
                   blue: CGFloat(b) / 255.0,
                   alpha: CGFloat(a) / 255.0)
}

fileprivate func uiColorToHex(_ ui: UIColor, includeAlpha: Bool = false) -> String? {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    if includeAlpha {
        return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    } else {
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

private struct PresetEditorView: View {
    let title: String
    @Binding var draft: PresetDraft
    @Binding var errorMessage: String?
    var onDismiss: () -> Void
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $draft.name)

                    // Interactive color picker with quick swatches and hex fallback
                    VStack(alignment: .leading, spacing: 8) {
                        ColorPicker("Accent Color", selection: Binding(get: {
                            draft.accentColor ?? Color.blue
                        }, set: { new in
                            draft.accentColor = new
                            draft.accentColorHex = uiColorToHex(UIColor(new)) ?? ""
                        }))

                        HStack(spacing: 10) {
                            // quick color swatches (hex strings)
                            ForEach(["#007AFF", "#34C759", "#FF9500", "#FF2D55", "#8E8E93"], id: \.self) { (hex: String) in
                                let swatch = uiColorFromHex(hex).map { Color(uiColor: $0) } ?? Color.blue
                                Button(action: {
                                    draft.accentColor = swatch
                                    draft.accentColorHex = hex
                                }) {
                                    Circle()
                                        .fill(swatch)
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 1))
                                }
                            }
                        }

                        TextField("Hex (fallback)", text: $draft.accentColorHex)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                    }
                }

                Section(header: Text("Durations")) {
                    Stepper(value: $draft.workMinutes, in: 1...240) {
                        HStack {
                            Text("Focus")
                            Spacer()
                            Text("\(draft.workMinutes) min")
                        }
                    }

                    Stepper(value: $draft.breakMinutes, in: 1...120) {
                        HStack {
                            Text("Break")
                            Spacer()
                            Text("\(draft.breakMinutes) min")
                        }
                    }

                    Stepper(value: $draft.cycles, in: 1...12) {
                        HStack {
                            Text("Cycles")
                            Spacer()
                            Text("\(draft.cycles)")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: onSave)
                        .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func dateTimeString(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

private struct PresetDraft {
    var name: String = ""
    var workMinutes: Int = 25
    var breakMinutes: Int = 5
    var cycles: Int = 4
    // interactive color selection
    var accentColor: Color? = nil
    // fallback hex text field (kept for backward compatibility)
    var accentColorHex: String = ""

    var workSeconds: TimeInterval { TimeInterval(workMinutes * 60) }
    var breakSeconds: TimeInterval { TimeInterval(breakMinutes * 60) }

    var normalizedAccent: String? {
        // prefer color picker value if set
        if let c = accentColor, let hex = uiColorToHex(UIColor(c)) {
            return hex
        }
        let trimmed = accentColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    init() {}

    init(preset: PresetViewData) {
        name = preset.displayTitle
        workMinutes = Int(preset.workDuration / 60)
        breakMinutes = Int(preset.breakDuration / 60)
        cycles = preset.cycles
        accentColorHex = preset.accentColorHex ?? ""
        if let hex = preset.accentColorHex, let ui = uiColorFromHex(hex) {
            accentColor = Color(uiColor: ui)
        }
    }
}

#if DEBUG
struct PresetManagementView_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.shared
        let store = PresetStore(persistence: persistence)
        PresetManagementView()
            .environmentObject(store)
    }
}
#endif
