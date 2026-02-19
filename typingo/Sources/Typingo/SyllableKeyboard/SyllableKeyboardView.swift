import SwiftUI

struct SyllableKeyboardView: View {
  let text: String
  @Binding var transcriptionText: String

  @State private var currentIndex: Int = 0
  @State private var displayedButtons: [Character] = []
  @State private var shakeCharacter: Character?
  @State private var wrongTapTrigger: Bool = false

  private let minimumButtonCount = 8

  private static let commonSyllables: [Character] = [
    "가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타", "파", "하",
    "은", "를", "이", "의", "고", "에", "도", "로", "서", "지", "기", "수", "대", "한",
    "것", "들", "그", "되", "보", "않", "없", "같", "우", "더", "때", "만", "어", "전",
    "중", "면", "새", "리", "위", "말", "일", "점", "원", "잘", "못", "날", "집", "밤"
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
      autoInsertNonKorean()
      regenerateButtons()
    }
    .onChange(of: text) { _, _ in
      currentIndex = 0
      transcriptionText = ""
      autoInsertNonKorean()
      regenerateButtons()
    }
    .onChange(of: transcriptionText) { _, newValue in
      if newValue.isEmpty {
        currentIndex = 0
        autoInsertNonKorean()
        regenerateButtons()
      }
    }
  }

  private func handleTap(_ character: Character) {
    guard currentIndex < targetCharacters.count else { return }

    let expected = nextKoreanCharacter()
    guard let expected else { return }

    if character == expected {
      transcriptionText.append(expected)
      currentIndex += 1
      autoInsertNonKorean()
      keyboardFeedback.impactOccurred(intensity: 0.6)
      regenerateButtons()
    } else {
      shakeCharacter = character
      wrongTapTrigger.toggle()
    }
  }

  private func nextKoreanCharacter() -> Character? {
    guard currentIndex < targetCharacters.count else { return nil }
    let char = targetCharacters[currentIndex]
    if char.isKorean {
      return char
    }
    return nil
  }

  private func autoInsertNonKorean() {
    while currentIndex < targetCharacters.count {
      let char = targetCharacters[currentIndex]
      if char.isKorean {
        break
      }
      transcriptionText.append(char)
      currentIndex += 1
    }
  }

  private func regenerateButtons() {
    let remaining = remainingKoreanCharacters()
    let unique = Array(Set(remaining))
    let decoyCount = max(0, minimumButtonCount - unique.count)
    let decoys = generateDecoys(count: decoyCount, excluding: Set(targetCharacters))
    var all = unique + decoys
    all.shuffle()
    displayedButtons = all
  }

  private func remainingKoreanCharacters() -> [Character] {
    var koreanCount = 0
    for i in 0..<min(currentIndex, targetCharacters.count) {
      if targetCharacters[i].isKorean {
        koreanCount += 1
      }
    }

    var remaining: [Character] = []
    var consumed = 0
    for char in targetCharacters where char.isKorean {
      if consumed < koreanCount {
        consumed += 1
      } else {
        remaining.append(char)
      }
    }
    return remaining
  }

  private func generateDecoys(count: Int, excluding: Set<Character>) -> [Character] {
    var decoys: [Character] = []
    var candidates = Self.commonSyllables.filter { !excluding.contains($0) }
    candidates.shuffle()

    for candidate in candidates {
      if decoys.count >= count { break }
      decoys.append(candidate)
    }

    if decoys.count < count {
      let hangulStart: UInt32 = 0xAC00
      let hangulEnd: UInt32 = 0xD7A3
      while decoys.count < count {
        let random = UInt32.random(in: hangulStart...hangulEnd)
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
  var isKorean: Bool {
    guard let scalar = unicodeScalars.first else { return false }
    // Hangul Syllables (AC00-D7A3) + Jamo (1100-11FF) + Compatibility Jamo (3130-318F)
    let value = scalar.value
    return (0xAC00...0xD7A3).contains(value)
        || (0x1100...0x11FF).contains(value)
        || (0x3130...0x318F).contains(value)
  }
}

