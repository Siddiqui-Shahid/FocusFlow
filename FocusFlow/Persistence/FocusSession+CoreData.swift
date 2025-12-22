import CoreData
import Foundation

@objc(FocusSession)
public class FocusSession: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var plannedDuration: Int64
    @NSManaged public var elapsedSeconds: Int64
    @NSManaged public var completed: Bool
    @NSManaged public var type: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var presetId: UUID?
}

extension FocusSession {
    static func create(in context: NSManagedObjectContext,
                       startTime: Date,
                       plannedDuration: TimeInterval,
                       type: String = "work",
                       presetId: UUID? = nil) -> FocusSession {
        let session = FocusSession(context: context)
        session.id = UUID()
        session.startTime = startTime
        session.plannedDuration = Int64(plannedDuration)
        session.elapsedSeconds = 0
        session.completed = false
        session.type = type
        session.createdAt = Date()
        session.presetId = presetId
        return session
    }
}
