import Foundation
import SwiftUI

@Observable
final class TypingoViewModel {
  var data: TypingoService.Response?
  
  func reloadScript(
    category: String,
    level: String,
    nativeLanguage: String,
    targetLanguage: String,
    model: OpenAIService.GPTModel
  ) async throws {
//    data = .init(
//      category: category,
//      level: level,
//      nativeLanguage: nativeLanguage,
//      targetLanguage: targetLanguage,
//      title: "예시",
//      subtitle: .init(
//        target: "sample",
//        native: "샘플"
//      ),
//      script: [
//        .init(
//          speaker: "😍 A", //😜 B
//          target: "Hello",
//          native: "안녕"
//        ),
//        .init(
//          speaker: "😜 B",
//          target: "Goodbye",
//          native: "안녕"
//        )
//      ],
//      keyExpressions: [
//        
//      ]
//    )
    let data = try await TypingoService().fetchScript(
      category: category,
      level: level,
      nativeLanguage: nativeLanguage,
      targetLanguage: targetLanguage,
      model: model
    )
    print(#function, model)
    print(#function, data)
    self.data = data
  }
}
