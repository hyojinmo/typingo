import SwiftUI

struct TextInputView: View {
  struct TextIO: Hashable {
    let title: String
    let text: String
    let onComplete: ((String) async throws -> Void)
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(title)
    }
    
    static func == (lhs: TextInputView.TextIO, rhs: TextInputView.TextIO) -> Bool {
      lhs.hashValue == rhs.hashValue
    }
  }
  
  @Binding var textIO: TextIO?
  
  @State private var text: String = ""
  @FocusState private var focused: Bool
  @State private var hasCommitted: Bool = false
  
  var body: some View {
    VStack {
      Spacer()
      
      VStack(spacing: 20) {
        HStack(spacing: 0) {
          HStack(spacing: 0) {
            Button {
              focused = false
            } label: {
              Image(systemName: "xmark")
                .imageScale(.small)
                .bold()
                .frame(width: 32, height: 32)
                .background {
                  Circle()
                    .fill(.regularMaterial)
                    .stroke(Color(.separator).gradient, lineWidth: 1)
                }
                .foregroundStyle(Color(.label))
            }
            
            Spacer(minLength: 0)
          }
          
          Text(textIO?.title ?? "Text")
            .foregroundStyle(Color(.label))
            .lineLimit(1)
          
          HStack(spacing: 0) {
            Spacer(minLength: 0)
            
            Button {
              if !text.isEmpty, text != textIO?.text {
                hasCommitted = true
                
                Task {
                  do {
                    try await textIO?.onComplete(text)
                  } catch {
                    print(error)
                  }
                  focused = false
                }
              } else {
                focused = false
              }
            } label: {
              Image(systemName: "checkmark")
                .imageScale(.small)
                .bold()
                .frame(width: 32, height: 32)
                .background {
                  Circle()
                    .fill(.regularMaterial)
                    .stroke(Color(.separator).gradient, lineWidth: 1)
                }
                .foregroundStyle(Color(.label))
                .overlay {
                  if hasCommitted {
                    ProgressView()
                  }
                }
            }
          }
        }
        
        TextField(
          textIO?.text ?? "Text",
          text: $text,
          axis: .vertical
        )
        .focused($focused)
      }
      .padding()
      .background {
        UnevenRoundedRectangle(
          cornerRadii: .init(topLeading: 24, topTrailing: 24)
        )
        .foregroundStyle(Color(.secondarySystemBackground))
      }
    }
    .background {
      Color(.systemBackground)
        .ignoresSafeArea()
        .opacity(focused ? 0.5 : 0)
        .animation(.default, value: focused)
        .onTapGesture {
          focused = false
        }
    }
    .task {
      focused = true
    }
    .onChange(of: focused) {
      if !focused {
        withAnimation(.default) {
          dismiss()
        }
      }
    }
  }
  
  private func dismiss() {
    focused = false
    textIO = nil
  }
}
