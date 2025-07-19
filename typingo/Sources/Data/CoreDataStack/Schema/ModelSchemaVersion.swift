import CoreData
import Foundation

enum ModelSchemaVersion: Sendable, CaseIterable {
  case v0
  
  static let momdName = "typingo"
  
  static var latestVersion: ModelSchemaVersion {
    return .allCases.last!
  }
  
  var modelName: String {
    switch self {
    case .v0:
      "typingo"
    }
  }
  
  var nextVersion: ModelSchemaVersion? {
    switch self {
    case .v0:
      return nil
    }
  }
  
  static func compatibleVersionForStoreMetadata(
    configuration: String,
    _ metadata: [String: Any]
  ) -> ModelSchemaVersion? {
    return ModelSchemaVersion.allCases.first(where: {
      guard
        let modelURL = Bundle
          .main
          .resourceURL?
          .appendingPathComponent(
            ModelSchemaVersion.momdName,
            isDirectory: true
          )
          .appendingPathExtension("momd")
          .appendingPathComponent(
            $0.modelName,
            isDirectory: false
          )
          .appendingPathExtension("mom"),
        let model = NSManagedObjectModel(contentsOf: modelURL)
      else {
        return false
      }
      
      return model.isConfiguration(
        withName: configuration,
        compatibleWithStoreMetadata: metadata
      )
    })
  }
  
  static var latestModel: NSManagedObjectModel? {
    guard
      let momdURL = Bundle
        .main
        .resourceURL?
        .appendingPathComponent(momdName, isDirectory: true)
        .appendingPathExtension("momd")
        .appendingPathComponent(ModelSchemaVersion.latestVersion.modelName)
        .appendingPathExtension("mom"),
      let managedObjectModel = NSManagedObjectModel(contentsOf: momdURL)
    else {
      return nil
    }
    
    return managedObjectModel
  }
}
