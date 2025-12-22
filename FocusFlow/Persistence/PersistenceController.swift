import CoreData
import Foundation

/// PersistenceController builds a Core Data stack with a programmatic model so this scaffold runs without an .xcdatamodeld.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Build model programmatically
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "FocusFlowModel", managedObjectModel: model)

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        // Enable lightweight migration so adding optional attributes does not break existing stores
        for desc in container.persistentStoreDescriptions {
            desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext { container.viewContext }
    func newBackgroundContext() -> NSManagedObjectContext { container.newBackgroundContext() }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // FocusSession entity
        let session = NSEntityDescription()
        session.name = "FocusSession"
        session.managedObjectClassName = "FocusSession"

        // Attributes
        func attr(_ name: String, _ type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = isOptional
            return a
        }

        session.properties = [
            attr("id", .UUIDAttributeType),
            attr("startTime", .dateAttributeType),
            attr("plannedDuration", .integer64AttributeType),
            attr("elapsedSeconds", .integer64AttributeType, isOptional: false),
            attr("completed", .booleanAttributeType),
            attr("type", .stringAttributeType, isOptional: true),
            attr("notes", .stringAttributeType, isOptional: true),
            attr("createdAt", .dateAttributeType, isOptional: false),
            attr("presetId", .UUIDAttributeType, isOptional: true)
        ]

        let preset = NSEntityDescription()
        preset.name = "Preset"
        preset.managedObjectClassName = "Preset"
        preset.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("workDuration", .integer64AttributeType),
            attr("breakDuration", .integer64AttributeType),
            attr("cycles", .integer16AttributeType, isOptional: false),
            attr("accentColorHex", .stringAttributeType, isOptional: true),
            attr("isDefault", .booleanAttributeType),
            attr("sortOrder", .integer16AttributeType, isOptional: false),
            attr("createdAt", .dateAttributeType, isOptional: false)
        ]

        model.entities = [session, preset]
        return model
    }
}
