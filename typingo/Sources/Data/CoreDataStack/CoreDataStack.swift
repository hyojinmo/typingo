import CoreData

public enum CoreDataStack {
  public enum Store: Sendable {
    enum Const {
      static let cloudContainerIdentifier = "iCloud.app.codeful.typingo"
    }

    public static func storeURL(for appGroup: String) -> URL {
      guard
        let fileContainer = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: appGroup
        )
      else {
        fatalError()
      }
      return fileContainer
    }

    static func createContainer(
      isEnabledCloudKitSync: Bool
    ) throws -> NSPersistentCloudKitContainer {
      let storeURL = storeURL(for: "group.app.codeful.typingo")
      let baseURL =
        storeURL
        .appendingPathComponent("typingo", isDirectory: true)
        .appendingPathComponent("LocalStorage", isDirectory: true)
      
      if !FileManager.default.fileExists(atPath: baseURL.path) {
        try FileManager.default.createDirectory(
          at: baseURL,
          withIntermediateDirectories: true
        )
      }

      let sqliteURL =
        baseURL
        .appendingPathComponent("LocalStorage")
        .appendingPathExtension("sqlite")

      print(sqliteURL)

      guard let managedObjectModel = ModelSchemaVersion.latestModel else {
        fatalError()
      }

      let container = NSPersistentCloudKitContainer(
        name: "LocalStorage",
        managedObjectModel: managedObjectModel
      )

      let defaultDescription = NSPersistentStoreDescription(url: sqliteURL)
      defaultDescription.shouldAddStoreAsynchronously = false
      defaultDescription.shouldInferMappingModelAutomatically = true
      defaultDescription.shouldMigrateStoreAutomatically = true

      if isEnabledCloudKitSync {
        defaultDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
          containerIdentifier: Const.cloudContainerIdentifier
        )
      }
      defaultDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
      defaultDescription.setOption(
        true as NSNumber,
        forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
      )

      container.persistentStoreDescriptions = [
        defaultDescription
      ]
      
      container.loadPersistentStores { _, error in
        if let error {
          print(error)
        }
      }
      
#if DEBUG
//      if isEnabledCloudKitSync {
//        try container.initializeCloudKitSchema()
//      }
#endif

      container.viewContext.automaticallyMergesChangesFromParent = true
      container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
      try container.viewContext.setQueryGenerationFrom(.current)

      return container
    }
  }
}
