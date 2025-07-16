import SwiftUI

struct KeyboardTutorialView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      // 아이콘 영역
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.1))
          .frame(width: 120, height: 120)
        
        Image(systemName: "keyboard")
          .font(.system(size: 50))
          .foregroundStyle(.blue)
      }
      
      // 텍스트 영역
      VStack(spacing: 16) {
        Text("Add keyboard")
          .font(.largeTitle)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
        
        Text("To learn a new language, you need to add a keyboard in System Settings.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
          .lineSpacing(2)
        
        VStack(alignment: .leading, spacing: 6) {
          Spacer()
          
          Text("\(Image(systemName: "1.circle.fill")) Open the Settings app on your iPhone or iPad.")
          
          Text("\(Image(systemName: "2.circle.fill")) \(Image(systemName: "gear")) General > \(Image(systemName: "keyboard")) Keyboard")
          
          Text("\(Image(systemName: "3.circle.fill")) Keyboards > Add New Keyboard")
          
          Spacer()
        }
        .font(.callout)
        .foregroundStyle(.primary)
      }
      
      Spacer()
      
      // 버튼 영역
      VStack(spacing: 12) {
        Button {
          dismiss()
        } label: {
          Text("Skip for Now")
            .font(.headline)
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 34)
    }
    .background(Color(.systemBackground))
  }
}
