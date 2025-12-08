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
            attr("createdAt", .dateAttributeType, isOptional: false)
        ]

        model.entities = [session]
        return model
    }
}
