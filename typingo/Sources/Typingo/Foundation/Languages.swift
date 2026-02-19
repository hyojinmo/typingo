import Foundation
import UIKit

struct Languages {
  struct Language: Sendable, Codable, Hashable {
    let languageCode: String
    let title: String
  }

  private static let virtualKeyboardLanguages: Set<String> = ["ko"]

  func nativeLanguages() -> [Language] {
    var languages = Locale.preferredLanguages
      .map {
        let languageCode = Locale(identifier: $0).language.languageCode?.identifier ?? $0
        return Language(
          languageCode: languageCode,
          title: Locale(identifier: $0).localizedString(forLanguageCode: $0) ?? languageCode.capitalized
        )
      }
      .uniqued(on: \.languageCode)

    let existingCodes = Set(languages.map(\.languageCode))
    let currentLocale = Locale.current
    for code in Self.virtualKeyboardLanguages where !existingCodes.contains(code) {
      languages.append(.init(
        languageCode: code,
        title: currentLocale.localizedString(forLanguageCode: code) ?? code.capitalized
      ))
    }

    return languages
  }

  @MainActor
  func targetLanguages() -> [Language] {
    var languages = keyboardLanguages()

    let existingCodes = Set(languages.map(\.languageCode))
    let currentLocale = Locale.current
    for code in Self.virtualKeyboardLanguages where !existingCodes.contains(code) {
      languages.append(.init(
        languageCode: code,
        title: currentLocale.localizedString(forLanguageCode: code) ?? code.capitalized
      ))
    }

    return languages
  }

  @MainActor
  static func needsVirtualKeyboard(for languageCode: String) -> Bool {
    guard virtualKeyboardLanguages.contains(languageCode) else { return false }
    #if DEBUG
    return true
    #else
    let hasSystemKeyboard = UITextInputMode.activeInputModes.contains { mode in
      guard let primary = mode.primaryLanguage else { return false }
      let code = Locale(identifier: primary).language.languageCode?.identifier ?? primary
      return code == languageCode
    }
    return !hasSystemKeyboard
    #endif
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
