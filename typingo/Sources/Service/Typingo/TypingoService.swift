import Foundation

struct TypingoService: Sendable {
  func fetchScript(
    category: String,
    level: String,
    nativeLanguage: String,
    targetLanguage: String
  ) async throws -> Response {
    print(#function, category, level, nativeLanguage, targetLanguage)
    return try await OpenAIService().chat(
      messages: [
        .init(
          role: .system,
          content: Prompt.generateScript(
            category: category,
            level: level,
            nativeLanguage: nativeLanguage,
            targetLanguage: targetLanguage
          )
        )
      ],
      model: .gpt4oMini
    )
  }
}
