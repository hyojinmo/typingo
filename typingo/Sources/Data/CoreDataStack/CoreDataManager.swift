@preconcurrency import CoreData
import Synchronization

public final class CoreDataManager: Sendable {
  private let container: Mutex<NSPersistentCloudKitContainer>
  public var viewContext: NSManagedObjectContext {
    get {
      container.withLock { $0.viewContext }
    }
  }
  
  public init(isEnabledCloudKitSync: Bool) {
    do {
      container = .init(
        try CoreDataStack.Store.createContainer(
          isEnabledCloudKitSync: isEnabledCloudKitSync
        )
      )
    } catch {
      print(error)
      fatalError(error.localizedDescription)
    }
  }
  
  public func performFetching<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    let context = container.withLock { $0.newBackgroundContext() }
    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    context.automaticallyMergesChangesFromParent = true
    return try context.performAndWait { [context] in
      try block(context)
    }
  }
  
  public func performWriting(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) throws {
    let context = container.withLock { $0.newBackgroundContext() }
    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    context.automaticallyMergesChangesFromParent = true
    try context.performAndWait { [context] in
      try block(context)
      if context.hasChanges {
        try context.save()
      }
    }
  }
}

extension CoreDataManager {
  public var enabledCloudKitSync: Bool {
    container.withLock { $0.persistentStoreDescriptions.first?.cloudKitContainerOptions != nil }
  }
  
  public func enableCloudKitSync(_ enabled: Bool) throws {
    try container.withLock {
      $0 = try CoreDataStack.Store.createContainer(
        isEnabledCloudKitSync: enabled
      )
    }
  }
}
