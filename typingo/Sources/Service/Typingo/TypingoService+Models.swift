import Foundation

extension TypingoService {
  struct Response: Sendable, Codable, Hashable {
    struct Expression: Sendable, Codable, Hashable {
      let target: String
      let native: String
    }
    
    struct Script: Sendable, Codable, Hashable {
      let speaker: String
      let target: String
      let native: String
    }
    
    let category: String
    let level: String
    let nativeLanguage: String
    let targetLanguage: String
    let title: String
    let subtitle: Expression
    let script: [Script]
    let keyExpressions: [Expression]
    let nextTopics: [String]
    let motivation: Script
  }
}

extension TypingoService.Response {
  func encoded() throws -> Data {
    return try PropertyListEncoder().encode(self)
  }
  
  init(from data: Data) throws {
    self = try PropertyListDecoder().decode(TypingoService.Response.self, from: data)
  }
}

extension TypingoService.Response: JSONSchemaRepresentable {
  static func reflectMirroring() -> TypingoService.Response {
    .init(
      category: "",
      level: "",
      nativeLanguage: "",
      targetLanguage: "",
      title: "",
      subtitle: .init(
        target: "",
        native: ""
      ),
      script: [],
      keyExpressions: [],
      nextTopics: [],
      motivation: .init(
        speaker: "",
        target: "",
        native: ""
      )
    )
  }
}
