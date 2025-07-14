import Foundation
import UIKit

struct Languages {
  struct Language: Sendable, Codable, Hashable {
    let languageCode: String
    let title: String
  }
  
  func nativeLanguages() -> [Language] {
    return Locale.preferredLanguages
      .map {
        let languageCode = Locale(identifier: $0).language.languageCode?.identifier ?? $0
        return .init(
          languageCode: languageCode,
          title: Locale(identifier: $0).localizedString(forLanguageCode: $0) ?? languageCode.capitalized
        )
      }
      .uniqued(on: \.languageCode)
  }
  
  @MainActor
  func targetLanguages() -> [Language] {
    keyboardLanguages()
  }
  
  private func commonLangues() -> [Language] {
    let commonLanguageCodes = [
      "en", "ko", "ja", "zh", "es", "fr", "de", "it", "pt", "ru",
      "ar", "hi", "th", "vi", "id", "ms", "tr", "nl", "sv", "da"
    ]
    
    let currentLocale = Locale.current
    
    return commonLanguageCodes
      .map { code in
        .init(
          languageCode: code,
          title: currentLocale.localizedString(forLanguageCode: code) ?? code.capitalized
        )
      }
      .uniqued(on: \.languageCode)
  }
  
  @MainActor
  private func keyboardLanguages() -> [Language] {
    let inputmodes = UITextInputMode.activeInputModes.compactMap({
      $0.primaryLanguage
    })
    return inputmodes
      .map {
        let languageCode = Locale(identifier: $0).language.languageCode?.identifier ?? $0
        return .init(
          languageCode: languageCode,
          title: Locale(identifier: $0).localizedString(forLanguageCode: $0) ?? languageCode.capitalized
        )
      }
      .uniqued(on: \.languageCode)
  }
}
