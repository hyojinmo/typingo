import Foundation
import CoreData

struct UserLessonLocalDataSource: Sendable {
  struct UserLessonModel: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let createdDate: Date
    let userId: String?
    
    let level: String
    let llmModel: String
    let nativeLanguage: String
    let targetLanguage: String
    let topic: String
    let typingoData: Data?
  }
  
  func fetchUserLessons(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil
  ) async throws -> [UserLessonModel] {
    try await AppConfiguration.shared.coreDataManager.fetchUserLessons(
      predicate: predicate,
      fetchLimit: fetchLimit,
      sortOrder: .forward
    )
  }
  
  func countForUserLessons(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil
  ) async throws -> Int {
    try await AppConfiguration.shared.coreDataManager.countForUserLesson(
      predicate: predicate,
      fetchLimit: fetchLimit,
      sortOrder: .forward
    )
  }
  
  func insertUserLesson(
    typingoData: TypingoService.Response,
    llmModel: String
  ) async throws {
    try await AppConfiguration.shared.coreDataManager.insertUserLesson(
      .init(
        id: .init(),
        createdDate: .now,
        userId: nil,
        level: typingoData.level,
        llmModel: llmModel,
        nativeLanguage: typingoData.nativeLanguage,
        targetLanguage: typingoData.targetLanguage,
        topic: typingoData.title,
        typingoData: try typingoData.encoded()
      )
    )
  }
}

extension UserLessonLocalDataSource {
  func observeChanges() -> AsyncStream<Void> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      let observingTask = Task {
        let stream = try await AppConfiguration.shared.coreDataManager.observeChangesStream(
          for: UserLessonEntity.self
        )
        for try await _ in stream {
          guard !Task.isCancelled else { break }
          continuation.yield()
        }
      }
      
      continuation.onTermination = { termination in
        observingTask.cancel()
      }
    }
  }
}


private extension UserLessonLocalDataSource.UserLessonModel {
  init(entity: UserLessonEntity) {
    id = entity.id ?? UUID()
    createdDate = entity.createdDate ?? .now
    userId = entity.userId
    level = entity.level ?? ""
    llmModel = entity.llmModel ?? ""
    nativeLanguage = entity.nativeLanguage ?? ""
    targetLanguage = entity.targetLanguage ?? ""
    topic = entity.topic ?? ""
    typingoData = entity.typingoData
  }
}

private extension CoreDataManager {
  func fetchUserLessons(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil,
    sortOrder: SortOrder
  ) async throws -> [UserLessonLocalDataSource.UserLessonModel] {
    try fetchUserLessonEntities(
      predicate: predicate,
      fetchLimit: fetchLimit,
      sortOrder: sortOrder
    )
    .map({ .init(entity: $0) })
  }
  
  func countForUserLesson(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil,
    sortOrder: SortOrder
  ) throws -> Int {
    let fetchRequest = self.userLessonFetchRequest(
      predicate: predicate,
      fetchLimit: fetchLimit,
      sortOrder: sortOrder
    )
    
    return try performFetching { context in
      return try context.count(for: fetchRequest)
    }
  }
  
  func insertUserLesson(
    _ userLesson: UserLessonLocalDataSource.UserLessonModel
  ) throws {
    try performWriting { context in
      let entity = UserLessonEntity(context: context)
      entity.id = userLesson.id
      entity.createdDate = userLesson.createdDate
      entity.userId = userLesson.userId
      entity.level = userLesson.level
      entity.llmModel = userLesson.llmModel
      entity.nativeLanguage = userLesson.nativeLanguage
      entity.targetLanguage = userLesson.targetLanguage
      entity.topic = userLesson.topic
      context.insert(entity)
    }
  }
}

private extension CoreDataManager {
  private func userLessonFetchRequest(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil,
    sortOrder: SortOrder
  ) -> NSFetchRequest<UserLessonEntity> {
    let fetchRequest = UserLessonEntity.fetchRequest()
    
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = [
      .init(
        keyPath: \UserLessonEntity.createdDate,
        ascending: sortOrder == .forward
      )
    ]
    
    if let fetchLimit {
      fetchRequest.fetchLimit = fetchLimit
    }
    
    return fetchRequest
  }
  
  private func fetchUserLessonEntities(
    predicate: NSPredicate? = nil,
    fetchLimit: Int? = nil,
    sortOrder: SortOrder
  ) throws -> [UserLessonEntity] {
    let fetchRequest = self.userLessonFetchRequest(
      predicate: predicate,
      fetchLimit: fetchLimit,
      sortOrder: sortOrder
    )
    
    return try performFetching { context in
      return try context.fetch(fetchRequest)
    }
  }
}
