import SwiftUI
import UIKit

struct SuppressedKeyboardTextField: UIViewRepresentable {
  @Binding var text: String
  var shouldBecomeFirstResponder: Bool

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.inputView = UIView(frame: .zero)
    textField.inputAccessoryView = UIView(frame: .zero)
    textField.autocorrectionType = .no
    textField.autocapitalizationType = .none
    textField.spellCheckingType = .no
    textField.textColor = .clear
    textField.tintColor = .clear
    textField.delegate = context.coordinator
    textField.addTarget(
      context.coordinator,
      action: #selector(Coordinator.textDidChange(_:)),
      for: .editingChanged
    )
    return textField
  }

  func updateUIView(_ textField: UITextField, context: Context) {
    if textField.text != text {
      textField.text = text
    }

    if shouldBecomeFirstResponder {
      if !textField.isFirstResponder {
        DispatchQueue.main.async {
          textField.becomeFirstResponder()
        }
      }
    } else {
      if textField.isFirstResponder {
        DispatchQueue.main.async {
          textField.resignFirstResponder()
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  final class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String

    init(text: Binding<String>) {
      _text = text
    }

    @objc func textDidChange(_ textField: UITextField) {
      var newText = textField.text ?? ""
      // Strip trailing newlines
      while newText.hasSuffix("\n") {
        newText.removeLast()
      }
      if text != newText {
        text = newText
      }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      false
    }
  }
}
