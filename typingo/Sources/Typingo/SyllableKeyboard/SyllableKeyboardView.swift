import SwiftUI

struct SyllableKeyboardView: View {
  let text: String
  let languageCode: String
  @Binding var transcriptionText: String

  @State private var currentIndex: Int = 0
  @State private var displayedButtons: [Character] = []
  @State private var shakeCharacter: Character?
  @State private var wrongTapTrigger: Bool = false

  private let maximumButtonCount = 8

  private static let koreanSyllables: [Character] = [
    "가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타", "파", "하",
    "은", "를", "이", "의", "고", "에", "도", "로", "서", "지", "기", "수", "대", "한",
    "것", "들", "그", "되", "보", "않", "없", "같", "우", "더", "때", "만", "어", "전",
    "중", "면", "새", "리", "위", "말", "일", "점", "원", "잘", "못", "날", "집", "밤"
  ]

  private static let japaneseSyllables: [Character] = [
    // Hiragana
    "あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ",
    "さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と",
    "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ",
    "ま", "み", "む", "め", "も", "や", "ゆ", "よ",
    "ら", "り", "る", "れ", "ろ", "わ", "を", "ん",
    // Katakana
    "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ",
    "サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト",
    "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ",
    "マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ",
    "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン",
    // Common kanji
    "日", "本", "人", "大", "中", "出", "見", "行", "生", "年",
    "時", "何", "思", "言", "私", "今", "前", "来", "子", "手"
  ]

  private static let chineseSyllables: [Character] = [
    "的", "一", "是", "不", "了", "人", "我", "在", "有", "他",
    "这", "中", "大", "来", "上", "国", "个", "到", "说", "们",
    "为", "子", "和", "你", "地", "出", "会", "时", "要", "也",
    "可", "就", "对", "以", "学", "家", "都", "能", "好", "下",
    "年", "生", "自", "天", "用", "工", "方", "多", "日", "行",
    "小", "没", "得", "那", "她", "后", "作", "心", "想", "去"
  ]

  private var targetCharacters: [Character] {
    Array(text)
  }

  private let keyboardFeedback = UIImpactFeedbackGenerator(style: .light)

  var body: some View {
    LazyVGrid(
      columns: [GridItem(.adaptive(minimum: 52), spacing: 8)],
      spacing: 8
    ) {
      ForEach(displayedButtons, id: \.self) { character in
        Button {
          handleTap(character)
        } label: {
          Text(String(character))
            .font(.title3)
            .fontWeight(.medium)
            .frame(minWidth: 52, minHeight: 44)
            .background {
              RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .stroke(Color(.separator), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .modifier(ShakeModifier(trigger: shakeCharacter == character && wrongTapTrigger))
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .sensoryFeedback(.warning, trigger: wrongTapTrigger)
    .onAppear {
      autoInsertNonTargetScript()
      regenerateButtons()
    }
    .onChange(of: text) { _, _ in
      currentIndex = 0
      transcriptionText = ""
      autoInsertNonTargetScript()
      regenerateButtons()
    }
    .onChange(of: transcriptionText) { _, newValue in
      if newValue.isEmpty {
        currentIndex = 0
        autoInsertNonTargetScript()
        regenerateButtons()
      }
    }
  }

  private func handleTap(_ character: Character) {
    guard currentIndex < targetCharacters.count else { return }

    let expected = nextTargetCharacter()
    guard let expected else { return }

    if character == expected {
      transcriptionText.append(expected)
      currentIndex += 1
      autoInsertNonTargetScript()
      keyboardFeedback.impactOccurred(intensity: 0.6)
      regenerateButtons()
    } else {
      shakeCharacter = character
      wrongTapTrigger.toggle()
    }
  }

  private func nextTargetCharacter() -> Character? {
    guard currentIndex < targetCharacters.count else { return nil }
    let char = targetCharacters[currentIndex]
    if char.isTargetScript {
      return char
    }
    return nil
  }

  private func autoInsertNonTargetScript() {
    while currentIndex < targetCharacters.count {
      let char = targetCharacters[currentIndex]
      if char.isTargetScript {
        break
      }
      transcriptionText.append(char)
      currentIndex += 1
    }
  }

  private func regenerateButtons() {
    let current = nextTargetCharacter()
    let decoyCount = maximumButtonCount - (current != nil ? 1 : 0)
    let excluding = Set(targetCharacters).union(current.map { Set([$0]) } ?? [])
    let decoys = generateDecoys(count: decoyCount, excluding: excluding)
    var all = decoys
    if let current { all.append(current) }
    all.shuffle()
    displayedButtons = all
  }

  private func remainingTargetCharacters() -> [Character] {
    var targetCount = 0
    for i in 0..<min(currentIndex, targetCharacters.count) {
      if targetCharacters[i].isTargetScript {
        targetCount += 1
      }
    }

    var remaining: [Character] = []
    var consumed = 0
    for char in targetCharacters where char.isTargetScript {
      if consumed < targetCount {
        consumed += 1
      } else {
        remaining.append(char)
      }
    }
    return remaining
  }

  private func generateDecoys(count: Int, excluding: Set<Character>) -> [Character] {
    var decoys: [Character] = []

    let pool: [Character]
    switch languageCode {
    case "ja":
      pool = Self.japaneseSyllables
    case "zh":
      pool = Self.chineseSyllables
    default:
      pool = Self.koreanSyllables
    }

    var candidates = pool.filter { !excluding.contains($0) }
    candidates.shuffle()

    for candidate in candidates {
      if decoys.count >= count { break }
      decoys.append(candidate)
    }

    if decoys.count < count {
      let fallbackRange: ClosedRange<UInt32>
      switch languageCode {
      case "ja":
        fallbackRange = 0x3040...0x309F // Hiragana
      case "zh":
        fallbackRange = 0x4E00...0x9FFF // CJK Unified Ideographs
      default:
        fallbackRange = 0xAC00...0xD7A3 // Hangul Syllables
      }
      while decoys.count < count {
        let random = UInt32.random(in: fallbackRange)
        if let scalar = Unicode.Scalar(random) {
          let char = Character(scalar)
          if !excluding.contains(char) && !decoys.contains(char) {
            decoys.append(char)
          }
        }
      }
    }

    return decoys
  }
}

private struct ShakeModifier: ViewModifier {
  var trigger: Bool
  @State private var offset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .offset(x: offset)
      .onChange(of: trigger) {
        withAnimation(.default.speed(6)) {
          offset = -6
        } completion: {
          withAnimation(.default.speed(6)) {
            offset = 6
          } completion: {
            withAnimation(.default.speed(6)) {
              offset = -4
            } completion: {
              withAnimation(.default.speed(6)) {
                offset = 0
              }
            }
          }
        }
      }
  }
}

private extension Character {
  var isTargetScript: Bool {
    guard let scalar = unicodeScalars.first else { return false }
    let value = scalar.value
    // Hangul Syllables + Jamo + Compatibility Jamo
    if (0xAC00...0xD7A3).contains(value)
        || (0x1100...0x11FF).contains(value)
        || (0x3130...0x318F).contains(value) {
      return true
    }
    // Hiragana
    if (0x3040...0x309F).contains(value) {
      return true
    }
    // Katakana + Katakana Phonetic Extensions
    if (0x30A0...0x30FF).contains(value)
        || (0x31F0...0x31FF).contains(value) {
      return true
    }
    // CJK Unified Ideographs
    if (0x4E00...0x9FFF).contains(value) {
      return true
    }
    // CJK Extension A
    if (0x3400...0x4DBF).contains(value) {
      return true
    }
    return false
  }
}
