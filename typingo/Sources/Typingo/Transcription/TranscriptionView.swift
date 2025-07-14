import SwiftUI

struct TranscriptionView: View {
  struct Appearance {
    let font: UIFont
    let foregroundColor: Color
    let placeholderColor: Color
    let backgroundColor: Color
    let accentColor: Color
    let highlightedColor: Color
  }
  
  @Environment(\.dismiss) private var dismiss
  
  let text: String
  let appearance: Appearance
  @Binding var isFocused: Bool
  let isExpired: Bool
  let onCompleted: () -> Void
  
  @State private var transcriptionText = ""
  @FocusState private var focusState: Bool
  
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
      .task(id: isFocused) {
        if isFocused {
          try? await Task.sleep(for: .seconds(0.3))
        }
        focusState = isFocused
      }
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
    let original = rawText.prefix(transcriptionText.count)
    let modified = transcriptionText
    
    var attributedString = AttributedString(transcriptionText)
    let originalChars = Array(original)
    let modifiedChars = Array(modified)
    
    let minLength = min(originalChars.count, modifiedChars.count)
    
    for i in 0..<minLength {
      if i == minLength - 1 {
        let range = attributedString.index(at: i)..<attributedString.index(at: i + 1)
        attributedString[range].foregroundColor = appearance.foregroundColor
        attributedString[range].backgroundColor = appearance.backgroundColor
      } else if originalChars[i] != modifiedChars[i] {
        let range = attributedString.index(at: i)..<attributedString.index(at: i + 1)
        attributedString[range].foregroundColor = appearance.accentColor
        attributedString[range].backgroundColor = appearance.highlightedColor
      }
    }
    
    return attributedString
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
    .focused($focusState)
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
    if let lastLine = transcriptionLines.last, let lineIndex = lines.firstIndex(of: lastLine), lineIndex < lines.count - 1 {
      return text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    } else {
      return text
    }
  }
  
  private func checkTranscriptionDifference() -> Bool {
    guard transcriptionText.count > 1 else { return false }
    let cursor = transcriptionText.count - 1
    let originalString = rawText.prefix(cursor)
    let currentString = transcriptionText.normalizeWhitespace().normalizeQuotes().prefix(cursor)
    return originalString != currentString
  }
  
  private func generateKeyboardFeedback() {
    transcriptionKeyboardFeedbackTask?.cancel()
    transcriptionKeyboardFeedbackTask = Task {
      keyboardFeedback.impactOccurred(intensity: 0.6)
      try? await Task.sleep(for: .seconds(0.1))
    }
  }
  
  private func checkTranscriptionCompletion() {
    transcriptionCompletionTask?.cancel()
    transcriptionCompletionTask = Task {
      guard !Task.isCancelled else { return }
      if transcriptionText.normalizeWhitespace() == rawText {
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
