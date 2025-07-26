import SwiftUI

struct TranscriptionNormalModeView: View {
  struct Appearance {
    let font: UIFont
    let foregroundColor: Color
    let placeholderColor: Color
    let backgroundColor: Color
    let accentColor: Color
    let highlightedColor: Color
    let allowedTypoColor: Color
    let allowedTypoBackgroundColor: Color
  }
  
  @Environment(\.dismiss) private var dismiss
  
  let text: String
  let appearance: Appearance
  let offset: Int
  @FocusState.Binding var focusStep: ContentView.Phase?
  let isExpired: Bool
  let onCompleted: () -> Void
  
  @State private var transcriptionText = ""
  
  @State private var numberOfLines: Int = 0
  
  @State private var transcriptionCompletionTask: Task<Void, Never>? {
    willSet {
      transcriptionCompletionTask?.cancel()
    }
  }
  
  private var rawText: String {
    text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .normalizeWhitespace()
      .normalizeQuotes()
  }
  
  @State private var originalText: String = ""
  
  @State private var textSize: CGSize = .zero
  @State private var lines: [String] = []
  
  @State private var transcriptionKeyboardFeedbackTask: Task<Void, Never>? {
    willSet {
      transcriptionCompletionTask?.cancel()
    }
  }
  
  @State private var isFinished = false
  
  private let keyboardFeedback = UIImpactFeedbackGenerator(style: .light)
  
  var body: some View {
    transcriptionContentView()
      .sensoryFeedback(.success, trigger: isFinished)
      .sensoryFeedback(.warning, trigger: checkTranscriptionDifference())
  }
  
  @ViewBuilder
  private func transcriptionContentView() -> some View {
    ZStack(alignment: .leading) {
      transcriptionPlaceholderView()
      transcriptionPreviewView()
      transcriptionTextView()
    }
    .font(.init(appearance.font))
    .lineSpacing(12)
    .lineLimit(numberOfLines, reservesSpace: true)
    .onGeometryChange(for: CGSize.self) { geometry in
      geometry.size
    } action: { newValue in
      textSize = newValue
      
      let text = rawText
      lines = linesFrom(text: text, font: appearance.font, width: newValue.width)
      originalText = lines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).joined(separator: "\n")
      numberOfLines = numberOfLines(in: originalText, font: appearance.font, width: newValue.width)
    }
  }
  
  @ViewBuilder
  private func transcriptionPlaceholderView() -> some View {
    Text(originalText)
      .foregroundStyle(isExpired ? appearance.foregroundColor : appearance.placeholderColor)
  }
  
  @ViewBuilder
  private func transcriptionPreviewView() -> some View {
    Text(previewText)
      .foregroundStyle(appearance.foregroundColor)
  }
  
  private var previewText: AttributedString {
    guard transcriptionText.count > 0 else { return AttributedString(transcriptionText) }
    let original = rawText
    let modified = transcriptionText
    
    // 대소문자와 특수문자를 원본에 맞게 보정한 텍스트 생성
    let correctedText = correctTypoText(original: original, typed: modified)
    var attributedString = AttributedString(correctedText)
    
    let originalChars = Array(original)
    let modifiedChars = Array(modified)
    let correctedChars = Array(correctedText)
    
    let minLength = min(originalChars.count, modifiedChars.count)
    
    for i in 0..<minLength {
      if i == minLength - 1 {
        let range = attributedString.index(at: i)..<attributedString.index(at: i + 1)
        attributedString[range].foregroundColor = appearance.foregroundColor
        attributedString[range].backgroundColor = appearance.backgroundColor
      } else if originalChars[i] != modifiedChars[i] {
        let range = attributedString.index(at: i)..<attributedString.index(at: i + 1)
        
        // 허용된 오타인지 진짜 오타인지 구분
        if charactersMatch(originalChars[i], modifiedChars[i]) {
          // 허용된 오타 (대소문자, 특수문자, 스페이스)
          attributedString[range].foregroundColor = appearance.allowedTypoColor
          attributedString[range].backgroundColor = appearance.allowedTypoBackgroundColor
        } else {
          // 진짜 오타 (허용되지 않는 오타)
          attributedString[range].foregroundColor = appearance.accentColor
          attributedString[range].backgroundColor = appearance.highlightedColor
        }
      }
    }
    
    return attributedString
  }
  
  // 대소문자와 특수문자 오타를 원본에 맞게 보정하는 함수
  private func correctTypoText(original: String, typed: String) -> String {
    let originalChars = Array(original)
    let typedChars = Array(typed)
    var correctedChars: [Character] = []
    
    let minLength = min(originalChars.count, typedChars.count)
    
    for i in 0..<minLength {
      let originalChar = originalChars[i]
      let typedChar = typedChars[i]
      
      if originalChar == typedChar {
        // 완전히 일치하는 경우
        correctedChars.append(typedChar)
      } else if String(originalChar).lowercased() == String(typedChar).lowercased() {
        // 대소문자만 다른 경우 - 원본 대소문자로 보정
        correctedChars.append(originalChar)
      } else if isSpecialCharacter(originalChar) && (isSpecialCharacter(typedChar) || typedChar == " ") {
        // 특수문자끼리 다른 경우 또는 특수문자 자리에 스페이스 - 원본 특수문자로 보정
        correctedChars.append(originalChar)
      } else if originalChar == " " && isSpecialCharacter(typedChar) {
        // 스페이스 자리에 특수문자 - 원본 스페이스로 보정
        correctedChars.append(originalChar)
      } else {
        // 그 외의 경우는 입력한 문자 그대로
        correctedChars.append(typedChar)
      }
    }
    
    return String(correctedChars)
  }
  
  @ViewBuilder
  private func transcriptionTextView() -> some View {
    TextField(
      "",
      text: $transcriptionText,
      axis: .vertical
    )
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)
    .foregroundStyle(Color.clear)
    .focused($focusStep, equals: .step(offset + 1))
    .onChange(of: $transcriptionText.wrappedValue, initial: false) { oldValue, newValue in
      var text = newValue
      if text.last == "\n" {
        text.removeLast()
      }
      updateTranscriptionString(text)
    }
  }
  
  @ViewBuilder
  private func transcriptionCountView() -> some View {
    Text("\(transcriptionText.normalizeWhitespace().count)/\(originalText.count)")
      .font(.caption)
      .foregroundStyle(Color.secondary)
  }
  
  private func updateTranscriptionString(_ string: String) {
    transcriptionText = String(string.prefix(originalText.count))
    transcriptionText = checkTranscriptionNewLine(text: transcriptionText).normalizeQuotes()
    
    generateKeyboardFeedback()
    checkTranscriptionCompletion()
  }
  
  private func checkTranscriptionNewLine(text: String) -> String {
    let transcriptionLines = linesFrom(text: text.trimmingCharacters(in: .whitespacesAndNewlines), font: appearance.font, width: textSize.width)
    
    // 현재 입력한 텍스트가 원본의 어떤 라인과 일치하는지 확인 (허용 규칙 적용)
    if let lastTranscriptionLine = transcriptionLines.last {
      for (lineIndex, originalLine) in lines.enumerated() {
        if lineIndex < lines.count - 1 && linesMatch(originalLine, lastTranscriptionLine) {
          return text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }
      }
    }
    
    return text
  }
  
  // 두 라인이 허용 규칙에 따라 일치하는지 확인하는 함수
  private func linesMatch(_ originalLine: String, _ transcriptionLine: String) -> Bool {
    let originalChars = Array(originalLine.trimmingCharacters(in: .whitespacesAndNewlines))
    let transcriptionChars = Array(transcriptionLine.trimmingCharacters(in: .whitespacesAndNewlines))
    
    // 길이가 다르면 일치하지 않음
    guard originalChars.count == transcriptionChars.count else {
      return false
    }
    
    // 모든 문자가 허용 규칙에 따라 매치되는지 확인
    for i in 0..<min(originalChars.count, transcriptionChars.count) {
      if !charactersMatch(originalChars[i], transcriptionChars[i]) {
        return false
      }
    }
    
    return true
  }
  
  // 수정된 부분: 특수문자와 대소문자 오타 허용 (스페이스도 허용)
  private func charactersMatch(_ original: Character, _ typed: Character) -> Bool {
    // 동일한 문자면 true
    if original == typed {
      return true
    }
    
    // 대소문자가 다른 경우 허용 (영문자인 경우)
    let originalStr = String(original)
    let typedStr = String(typed)
    let originalLower = originalStr.lowercased()
    let typedLower = typedStr.lowercased()
    
    if originalLower == typedLower && originalStr != typedStr {
      return true
    }
    
    // 특수문자끼리는 오타 허용 (둘 다 특수문자면 true)
    // 또는 특수문자 자리에 스페이스를 입력해도 허용
    if isSpecialCharacter(original) && (isSpecialCharacter(typed) || typed == " ") {
      return true
    }
    
    // 스페이스 자리에 특수문자를 입력해도 허용
    if original == " " && isSpecialCharacter(typed) {
      return true
    }
    
    return false
  }
  
  // 특수문자 판별 함수
  private func isSpecialCharacter(_ char: Character) -> Bool {
    let specialChars = CharacterSet.punctuationCharacters
      .union(.symbols)
    
    return char.unicodeScalars.allSatisfy { specialChars.contains($0) }
  }
  
  private func checkTranscriptionDifference() -> Bool {
    guard transcriptionText.count > 1 else { return false }
    let cursor = transcriptionText.count - 1
    let originalChars = Array(rawText.prefix(cursor))
    let currentChars = Array(transcriptionText.normalizeWhitespace().normalizeQuotes().prefix(cursor))
    
    if originalChars.count != currentChars.count {
      return true
    }
    
    // 허용되지 않는 실제 오타가 있는지 확인 (시각적 피드백용)
    for i in 0..<min(originalChars.count, currentChars.count) {
      if !charactersMatch(originalChars[i], currentChars[i]) {
        return true
      }
    }
    
    return false
  }
  
  private func generateKeyboardFeedback() {
    transcriptionKeyboardFeedbackTask?.cancel()
    transcriptionKeyboardFeedbackTask = Task {
      keyboardFeedback.impactOccurred(intensity: 0.6)
      try? await Task.sleep(for: .seconds(0.1))
    }
  }
  
  // 수정된 완료 체크 로직
  private func checkTranscriptionCompletion() {
    transcriptionCompletionTask?.cancel()
    transcriptionCompletionTask = Task {
      guard !Task.isCancelled else { return }
      
      let normalizedTranscription = transcriptionText.normalizeWhitespace()
      let normalizedOriginal = rawText
      
      // 길이가 같아야 완료
      guard normalizedTranscription.count == normalizedOriginal.count else {
        return
      }
      
      let originalChars = Array(normalizedOriginal)
      let transcriptionChars = Array(normalizedTranscription)
      
      // 모든 문자가 매치되는지 확인 (특수문자와 대소문자는 오타 허용)
      var allMatch = true
      for i in 0..<min(originalChars.count, transcriptionChars.count) {
        let originalChar = originalChars[i]
        let transcriptionChar = transcriptionChars[i]
        
        if !charactersMatch(originalChar, transcriptionChar) {
          allMatch = false
          break
        }
      }
      
      if allMatch {
        isFinished = true
        onCompleted()
      }
    }
  }
  
  private func numberOfLines(in text: String, font: UIFont, width: CGFloat) -> Int {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byWordWrapping
    paragraphStyle.lineSpacing = 12
    paragraphStyle.lineBreakStrategy = .standard
    
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .paragraphStyle: paragraphStyle
    ]
    
    let textSize = (text as NSString).boundingRect(
      with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes,
      context: nil
    )
    
    let lineHeight = font.lineHeight
    return Int(ceil(textSize.height / lineHeight))
  }
  
  private func linesFrom(text: String, font: UIFont, width: CGFloat) -> [String] {
    let textStorage = NSTextStorage(string: text)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    textContainer.widthTracksTextView = false
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byWordWrapping
    paragraphStyle.lineSpacing = 12
    paragraphStyle.lineBreakStrategy = .standard
    
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    textStorage.addAttribute(.font, value: font, range: NSRange(location: 0, length: textStorage.length))
    textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: textStorage.length))
    
    var lines: [String] = []
    var lastIndex: Int = 0
    
    layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: layoutManager.numberOfGlyphs)) { _, usedRect, textContainer, glyphRange, _ in
      let range = Range(glyphRange, in: text)!
      let lineText = String(text[range])
      lines.append(lineText.trimmingCharacters(in: .whitespacesAndNewlines))
      lastIndex = glyphRange.upperBound
    }
    
    // 남은 텍스트가 있다면 추가 (개행 처리)
    if lastIndex < text.count {
      let remainingText = String(text[text.index(text.startIndex, offsetBy: lastIndex)...])
      lines.append(remainingText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    return lines
  }
}

private extension AttributedString {
  func index(at offset: Int) -> AttributedString.Index {
    self.index(startIndex, offsetByCharacters: offset)
  }
}

private extension String {
  func normalizeWhitespace() -> String {
    let pattern = "\\s+" // 모든 공백(스페이스, 탭, 개행 등) 패턴
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: " ")
  }
  
  func normalizeNewlines() -> String {
    let pattern = "[ \\t]*\\n+" // 공백(스페이스, 탭) 뒤에 오는 개행 문자 패턴
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "\n")
  }
  
  func normalizeQuotes() -> String {
    let replacements: [(String, String)] = [
      ("‘", "'"), ("’", "'"), // 작은따옴표 (왼쪽, 오른쪽)
      ("“", "\""), ("”", "\""), // 큰따옴표 (왼쪽, 오른쪽)
      ("‚", "'"), ("„", "\"")  // 기타 변형 따옴표
    ]
    
    var normalizedText = self
    for (original, replacement) in replacements {
      normalizedText = normalizedText.replacingOccurrences(of: original, with: replacement)
    }
    return normalizedText
  }
  
  func normalizePunctuation() -> String {
    let replacements: [(String, String)] = [
      ("‘", "'"), ("’", "'"),  // 작은따옴표 (왼쪽, 오른쪽)
      ("“", "\""), ("”", "\""),  // 큰따옴표 (왼쪽, 오른쪽)
      ("‚", "'"), ("„", "\""),  // 기타 변형 따옴표
      ("․", "."), ("‥", ".."), ("…", "..."),  // 마침표 (단일, 이중, 삼중 점)
      ("，", ","), ("｡", "."), ("．", "."),  // 쉼표 및 일본어/중국어 마침표
      ("﹒", "."), ("·", "."), ("･", "."),  // 점(.) 변형들
      ("﹐", ","), ("、", ","), ("‚", ",")  // 쉼표(, 변형)
    ]
    
    var normalizedText = self
    for (original, replacement) in replacements {
      normalizedText = normalizedText.replacingOccurrences(of: original, with: replacement)
    }
    return normalizedText
  }
}
