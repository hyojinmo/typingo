@preconcurrency import CoreData

extension CoreDataManager {
  public struct CoreDataChange<T: Sendable>: Sendable {
    let inserted: [T]
    let updated: [T]
    let deleted: [T]
    
    var hasChanges: Bool {
      !inserted.isEmpty || !updated.isEmpty || !deleted.isEmpty
    }
  }
  
  public func observeChangesStream<T: NSManagedObject>(
    for entityType: T.Type
  ) throws -> AsyncThrowingStream<CoreDataChange<T>, Swift.Error> {
    return AsyncThrowingStream { continuation in
      let notificationCenter = NotificationCenter.default
      let observer = notificationCenter.addObserver(
        forName: .NSManagedObjectContextDidMergeChangesObjectIDs,
        object: nil,
        queue: .main
      ) { notification in
        guard let userInfo = notification.userInfo else { return }
        
        let inserted = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
          .filter({ objectID in objectID.entity == T.entity() })
          .compactMap { $0 as? T }
        let updated = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [])
          .filter({ objectID in objectID.entity == T.entity() })
          .compactMap { $0 as? T }
        let deleted = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [])
          .filter({ objectID in objectID.entity == T.entity() })
          .compactMap { $0 as? T }
        
        let change = CoreDataChange(
          inserted: inserted,
          updated: updated,
          deleted: deleted
        )
        
        continuation.yield(change)
      }
      
      continuation.onTermination = { _ in
        notificationCenter.removeObserver(observer)
      }
    }
  }
}
