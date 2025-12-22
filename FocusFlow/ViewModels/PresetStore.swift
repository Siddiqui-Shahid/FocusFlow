import CoreData
import Foundation
import SwiftUI

struct PresetViewData: Identifiable, Equatable {
    let objectID: NSManagedObjectID
    let id: UUID
    var name: String
    var workDuration: TimeInterval
    var breakDuration: TimeInterval
    var cycles: Int
    var accentColorHex: String?
    var isDefault: Bool
    var sortOrder: Int

    // Precompiled regex to remove trailing " <digits>/<digits>" pattern from the name.
    private static let displayTitleRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: "\\s\\d+\\/\\d+$",
        options: []
    )

    // A cleaned title that strips duration hints from the name (e.g. "Pomodoro 25/5" -> "Pomodoro")
    var displayTitle: String {
        guard let regex = Self.displayTitleRegex else {
            return name
        }
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        let cleaned = regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var workMinutes: Int { Int(workDuration / 60) }
    var breakMinutes: Int { Int(breakDuration / 60) }

    init?(managedObject: Preset) {
        guard let identifier = managedObject.id,
              let presetName = managedObject.name else { return nil }
        objectID = managedObject.objectID
        id = identifier
        name = presetName
        workDuration = TimeInterval(managedObject.workDuration)
        breakDuration = TimeInterval(managedObject.breakDuration)
        cycles = Int(managedObject.cycles)
        accentColorHex = managedObject.accentColorHex
        isDefault = managedObject.isDefault
        sortOrder = Int(managedObject.sortOrder)
    }
}

enum PresetStoreError: LocalizedError {
    case emptyName
    case invalidDuration

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Preset name cannot be empty."
        case .invalidDuration:
            return "Work and break durations must be greater than zero."
        }
    }
}

@MainActor
final class PresetStore: ObservableObject {
    @Published private(set) var presets: [PresetViewData] = []

    private let persistence: PersistenceController
    private let viewContext: NSManagedObjectContext

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.viewContext = persistence.viewContext
        seedDefaultsIfNeeded()
        loadPresets()
    }

    func loadPresets() {
        let request: NSFetchRequest<Preset> = Preset.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Preset.sortOrder), ascending: true),
            NSSortDescriptor(key: #keyPath(Preset.createdAt), ascending: true)
        ]

        do {
            let managed = try viewContext.fetch(request)
            presets = managed.compactMap(PresetViewData.init)
        } catch {
            presets = []
        }
    }

    func preset(with id: UUID?) -> PresetViewData? {
        guard let id else { return presets.first }
        return presets.first { $0.id == id }
    }

    func addPreset(name: String,
                   workDuration: TimeInterval,
                   breakDuration: TimeInterval,
                   cycles: Int = 4,
                   accentColorHex: String? = nil) throws {
        try validate(name: name, work: workDuration, brk: breakDuration)
        let nextSort = (presets.map { $0.sortOrder }.max() ?? -1) + 1
        _ = Preset.create(in: viewContext,
                          name: name,
                          workDuration: workDuration,
                          breakDuration: breakDuration,
                          cycles: cycles,
                          accentColorHex: accentColorHex,
                          isDefault: false,
                          sortOrder: nextSort)
        try viewContext.save()
        loadPresets()
    }

    func update(preset: PresetViewData,
                name: String,
                workDuration: TimeInterval,
                breakDuration: TimeInterval,
                cycles: Int,
                accentColorHex: String?) throws {
        try validate(name: name, work: workDuration, brk: breakDuration)
        guard let object = try? viewContext.existingObject(with: preset.objectID) as? Preset else {
            return
        }
        object.name = name
        object.workDuration = Int64(workDuration)
        object.breakDuration = Int64(breakDuration)
        object.cycles = Int16(cycles)
        object.accentColorHex = accentColorHex
        try viewContext.save()
        loadPresets()
    }

    func delete(_ preset: PresetViewData) {
        guard let object = try? viewContext.existingObject(with: preset.objectID) else { return }
        viewContext.delete(object)
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
        loadPresets()
    }

    private func validate(name: String, work: TimeInterval, brk: TimeInterval) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PresetStoreError.emptyName
        }
        guard work > 0, brk > 0 else {
            throw PresetStoreError.invalidDuration
        }
    }

    private func seedDefaultsIfNeeded() {
        let request: NSFetchRequest<Preset> = Preset.fetchRequest()
        request.fetchLimit = 1
        let existingCount = (try? viewContext.count(for: request)) ?? 0
        guard existingCount == 0 else { return }

        let defaults: [(String, TimeInterval, TimeInterval, Int, String?)] = [
            ("Pomodoro 25/5", 25 * 60, 5 * 60, 4, "#FF5E57"),
            ("Short Sprint 15/3", 15 * 60, 3 * 60, 5, "#4BCFFA"),
            ("Deep Work 50/10", 50 * 60, 10 * 60, 2, "#0BE881")
        ]

        for (index, preset) in defaults.enumerated() {
            _ = Preset.create(in: viewContext,
                              name: preset.0,
                              workDuration: preset.1,
                              breakDuration: preset.2,
                              cycles: preset.3,
                              accentColorHex: preset.4,
                              isDefault: true,
                              sortOrder: index)
        }

        try? viewContext.save()
    }
}
