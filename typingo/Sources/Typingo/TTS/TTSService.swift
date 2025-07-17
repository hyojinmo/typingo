import Foundation
import Speech

@MainActor
@Observable
final class TTSService: NSObject {
  private let synthesizer = AVSpeechSynthesizer()
  
  private var onFinished: (() -> Void)?
  
  override init() {
    super.init()
    
    synthesizer.delegate = self
  }
}

extension TTSService {
  func speak(text: String, withVoice voiceIdentifier: String? = nil, languageCode: String?) async throws {
    let audioSession = AVAudioSession.sharedInstance()
    
    try audioSession.setCategory(
      .playback,
      mode: .voicePrompt,
      options: [.duckOthers]
    )
    try audioSession.setActive(
      true,
      options: .notifyOthersOnDeactivation
    )
    
    let utterance = AVSpeechUtterance(string: text)
    if let voiceId = voiceIdentifier, let selectedVoice = AVSpeechSynthesisVoice(identifier: voiceId) {
      utterance.voice = selectedVoice
    } else if let languageCode {
      utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
    } else {
      let defaultLanguage = Locale.current.language.languageCode?.identifier ?? "en-US"
      utterance.voice = AVSpeechSynthesisVoice(language: defaultLanguage)
    }
    
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    
    synthesizer.speak(utterance)
    
    await withCheckedContinuation { [weak self] continuation in
      self?.onFinished = {
        continuation.resume()
      }
    }
  }
  
  func stopSpeaking() throws {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
      try restoreAudioSession()
    }
  }
  
  private func restoreAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
  }
}

extension TTSService: AVSpeechSynthesizerDelegate {
  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    
  }
  
  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    Task { @MainActor in
      onFinished?()
      onFinished = nil
    }
  }
  
  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    Task { @MainActor in
      onFinished?()
      onFinished = nil
    }
  }
}
