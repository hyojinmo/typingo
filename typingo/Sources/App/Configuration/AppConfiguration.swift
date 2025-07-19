import Foundation

@globalActor
actor AppConfiguration: Sendable {
  static let shared = AppConfiguration()
  
  private(set) var coreDataManager: CoreDataManager
  
  private init() {
    self.coreDataManager = CoreDataManager(
      isEnabledCloudKitSync: false
    )
  }
}
