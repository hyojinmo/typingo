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
      nextTopics: []
    )
  }
}
