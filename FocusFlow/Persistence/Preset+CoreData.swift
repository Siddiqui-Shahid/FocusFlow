import CoreData
import Foundation

@objc(Preset)
public class Preset: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Preset> {
        NSFetchRequest<Preset>(entityName: "Preset")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var workDuration: Int64
    @NSManaged public var breakDuration: Int64
    @NSManaged public var cycles: Int16
    @NSManaged public var accentColorHex: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
}

extension Preset {
    static func create(in context: NSManagedObjectContext,
                       id: UUID = UUID(),
                       name: String,
                       workDuration: TimeInterval,
                       breakDuration: TimeInterval,
                       cycles: Int = 4,
                       accentColorHex: String? = nil,
                       isDefault: Bool = false,
                       sortOrder: Int = 0) -> Preset {
        let preset = Preset(context: context)
        preset.id = id
        preset.name = name
        preset.workDuration = Int64(workDuration)
        preset.breakDuration = Int64(breakDuration)
        preset.cycles = Int16(cycles)
        preset.accentColorHex = accentColorHex
        preset.isDefault = isDefault
        preset.sortOrder = Int16(sortOrder)
        preset.createdAt = Date()
        return preset
    }
}
