//
//  ContentView.swift
//  typingo
//
//  Created by HYOJIN MO on 7/11/25.
//

import SwiftUI

struct ContentView: View {
  @AppStorage("category") private var category: String = "KPop"
  @AppStorage("level") private var level: Levels = .beginner
  @AppStorage("nativeLanguage") var nativeLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
  @AppStorage("targetLanguage") var targetLanguage: String = {
    if Locale.current.language.languageCode?.identifier == "en" {
      return "ko"
    } else {
      return "en"
    }
  }()
  @AppStorage("typingoData") private var typingoData: Data?
  
  enum Phase: Hashable, Comparable {
    case none
    case ready
    case loading
    case started
    case step(Int)
    case finished
    
    static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.step < rhs.step
    }
    
    static func > (lhs: Self, rhs: Self) -> Bool {
      lhs.step > rhs.step
    }
    
    static func <= (lhs: Self, rhs: Self) -> Bool {
      lhs.step <= rhs.step
    }
    
    static func >= (lhs: Self, rhs: Self) -> Bool {
      lhs.step >= rhs.step
    }
    
    private var step: Int {
      switch self {
      case .none:
        0
      case .ready:
        1
      case .loading:
        2
      case .started:
        3
      case .step:
        4
      case .finished:
        5
      }
    }
  }
  
  struct PhaseAnimationStep<Value: Hashable>: Hashable {
    let value: Value
    let delay: Double
  }
  
  @State private var viewModel = TypingoViewModel()
  
  @State private var phase: Phase = .none
  
  var body: some View {
    ScrollView {
      VStack(spacing: 40) {
        if phase <= .loading {
          Spacer()
            .containerRelativeFrame(.vertical) { height, _ in height * 0.25 }
        }
        
        VStack {
          Menu {
            #if DEBUG
            menuView()
            #endif
          } label: {
            Text(verbatim: "🐡")
              .imageScale(.large)
              .font(.largeTitle)
              .fontWeight(.black)
              .fontDesign(.monospaced)
              .phaseAnimator(
                [
                  PhaseAnimationStep(
                    value: 0.0,
                    delay: 0.0
                  ),
                  PhaseAnimationStep(
                    value: 15.0,
                    delay: 2.0
                  ),
                  PhaseAnimationStep(
                    value: -10.0,
                    delay: 0.0
                  ),
                  PhaseAnimationStep(
                    value: 15.0,
                    delay: 0.0
                  )
                ]
              ) {
                content,
                phase in
                content
                  .rotationEffect(
                    .degrees(phase.value),
                    anchor: .init(
                      x: 0.5,
                      y: 0.5
                    )
                  )
              } animation: { phase in
                  .spring(duration: 0.2)
                  .delay(phase.delay)
              }
          }
          .menuActionDismissBehavior(.disabled)
          
          if phase >= .ready {
            logoView()
          }
        }
        
        if phase >= .ready {
          streakView()
        }
        
        if let data = viewModel.data,
           phase > .loading
        {
          DividerLabel(
            text: "🎯"
          )
          
          scriptTitleView(data: data)
          
          DividerLabel(
            text: "⌨️"
          )
          
          if case .step(let step) = phase {
            scriptView(
              data: data,
              step: step
            )
          } else if phase == .finished {
            scriptView(
              data: data,
              step: data.script.count
            )
          }
          
          if phase == .finished {
            DividerLabel(
              text: "🔑"
            )
            
            keyExpressionView(data: data)
              .transition(
                .asymmetric(
                  insertion: .init(
                    .blurReplace.animation(.snappy.delay(1))
                  ),
                  removal: .init(
                    .blurReplace
                  )
                )
              )
            
            DividerLabel(
              text: "🔥"
            )
            .transition(
              .asymmetric(
                insertion: .init(
                  .blurReplace.animation(.snappy.delay(3))
                ),
                removal: .init(
                  .blurReplace
                )
              )
            )
            
            nextTopicView(data: data)
              .transition(
                .asymmetric(
                  insertion: .init(
                    .blurReplace.animation(.snappy.delay(4))
                  ),
                  removal: .init(
                    .blurReplace
                  )
                )
              )
          }
        } else if phase == .ready {
          startButton()
        } else if phase == .loading {
          progressView()
        }
      }
      .padding()
    }
    .safeAreaInset(edge: .bottom) {
      if case .step(let step) = phase,
         let data = viewModel.data, data.script.indices.contains(step - 1)
      {
        let progress = Double(step - 1) / Double(data.script.count)
        GeometryReader { geometry in
          Rectangle()
            .fill(.regularMaterial)
            .overlay(alignment: .leading) {
              Rectangle()
                .fill(Color(.label))
                .frame(width: max(1, geometry.size.width * progress))
            }
        }
        .frame(height: 4)
      }
    }
    .animation(.snappy, value: phase)
    .animation(.snappy, value: viewModel.data)
    .task {
      try? await Task.sleep(for: .seconds(1))
      
      phase = .ready
      
      do {
        try await restoreTypingoData()
      } catch {
        print(error)
      }
    }
    .sensoryFeedback(.increase, trigger: phase)
  }
}

extension ContentView {
  @ViewBuilder
  private func menuView() -> some View {
    Section("Languages") {
      nativeLanguagePicker()
      
      targetLanguagePicker()
    }
    
    Section("Topics") {
      topicPicker()
    }
    
    ControlGroup("Levels") {
      levelPicker()
    }
    
    ControlGroup {
      if phase == .ready {
        Button {
          startTypingo()
        } label: {
          Image(systemName: "play.fill")
          
          Text("Start")
        }
        .foregroundStyle(Color.yellow, Color(.label))
      } else {
        Button(role: .destructive) {
          restartTypingo()
        } label: {
          Text("Restart")
          
          Text("Restart the ongoing learning process.")
        }
      }
    }
  }
  
  @ViewBuilder
  private func nativeLanguagePicker() -> some View {
    Menu {
      Picker(
        selection: $nativeLanguage,
        content: {
          ForEach(Languages().nativeLanguages(), id: \.languageCode) { language in
            Text(language.title)
          }
        },
        label: {
          Text("Native language")
        }
      )
    } label: {
      if let language = Languages().nativeLanguages().first(where: { $0.languageCode == nativeLanguage }) {
        Text(language.title)
      }
      
      Text("Native language")
    }
  }
  
  @ViewBuilder
  private func targetLanguagePicker() -> some View {
    Menu {
      Picker(
        selection: $targetLanguage,
        content: {
          ForEach(Languages().targetLanguages(), id: \.languageCode) { language in
            Text(language.title)
          }
        },
        label: {
          Text("Language to learn")
        }
      )
    } label: {
      if let language = Languages().targetLanguages().first(where: { $0.languageCode == targetLanguage }) {
        Text(language.title)
      }
      
      Text("Language to learn")
    }
  }
  
  @ViewBuilder
  private func topicPicker() -> some View {
    Menu {
      Picker(
        selection: $category) {
          ForEach(Topics().presets(), id: \.self) { topic in
            Text(topic)
          }
        } label: {
          Text("Topics")
        }
    } label: {
      Text(category)
    }
  }
  
  @ViewBuilder
  private func levelPicker() -> some View {
    ForEach(Levels.allCases, id: \.self) { level in
      Button {
        self.level = level
      } label: {
        HStack {
          if level == self.level {
            Image(systemName: "checkmark.circle.fill")
          } else {
            Image(systemName: "circle")
          }
          Text(level.rawValue)
        }
      }
    }
  }
  
  @ViewBuilder
  private func logoView() -> some View {
    HStack(spacing: 4) {
      Text(verbatim: "Typingo")
        .font(.largeTitle)
        .fontWeight(.black)
        .fontDesign(.monospaced)
      
      Rectangle()
        .frame(width: 2)
        .padding(.vertical, 4)
        .phaseAnimator(
          [
            PhaseAnimationStep(
              value: 0.0,
              delay: 0.1
            ),
            PhaseAnimationStep(
              value: 1.0,
              delay: 0.0
            )
          ]
        ) {
          content,
          phase in
          content
            .opacity(phase.value)
        } animation: { phase in
            .default
            .delay(phase.delay)
        }
    }
    .fixedSize(horizontal: false, vertical: true)
    .transition(.blurReplace.combined(with: .scale).animation(.snappy.delay(0.2)))
    
    Text("Learn by typing")
      .font(.caption)
      .foregroundStyle(.secondary)
      .transition(.blurReplace.combined(with: .scale).animation(.snappy.delay(0.5)))
  }
  
  @ViewBuilder
  private func streakView() -> some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        
        Image(systemName: "laurel.leading")
          .font(.largeTitle)
        
        Text(verbatim: "1")
          .font(.largeTitle)
          .fontWeight(.black)
          .italic()
          .contentTransition(.numericText(value: 1))
        
        Image(systemName: "laurel.trailing")
          .font(.largeTitle)
        
        Spacer()
      }
      
      Text("Types")
        .font(.caption2)
        .italic()
    }
    .transition(.blurReplace.combined(with: .scale).animation(.snappy.delay(1)))
  }
  
  @ViewBuilder
  private func startButton() -> some View {
    Menu {
      menuView()
    } label: {
      HStack {
        Text("Start")
      }
      .font(.largeTitle)
      .fontWeight(.black)
      .italic()
      .foregroundStyle(Color(.label))
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
      .background {
        Capsule()
          .fill(.regularMaterial)
          .stroke(.thickMaterial)
      }
    }
    .transition(
      .asymmetric(
        insertion: .init(
          .blurReplace.combined(with: .scale).animation(.snappy.delay(2))
        ),
        removal: .init(
          .blurReplace.combined(with: .scale)
        )
      )
    )
    .menuActionDismissBehavior(.disabled)
  }
  
  @ViewBuilder
  private func progressView() -> some View {
    HStack {
      ProgressView()
        .progressViewStyle(.circular)
        .controlSize(.mini)
      
      Text("Prepare script...")
    }
    .font(.largeTitle)
    .fontWeight(.black)
    .italic()
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background {
      Capsule()
        .fill(.regularMaterial)
        .stroke(.thickMaterial)
    }
    .transition(
      .blurReplace.combined(with: .scale)
    )
  }
  
  @ViewBuilder
  private func scriptTitleView(data: TypingoService.Response) -> some View {
    Text(data.title)
      .font(.title2)
      .fontWeight(.bold)
      .multilineTextAlignment(.center)
      .transition(
        .asymmetric(
          insertion: .init(
            .blurReplace.combined(with: .scale).animation(.snappy.delay(0.2)),
          ),
          removal: .init(
            .blurReplace.combined(with: .scale).animation(.snappy.delay(0.3))
          )
        )
      )
    
    VStack {
      Text(data.subtitle.native)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      
      Text(data.subtitle.target)
        .font(.body)
        .multilineTextAlignment(.center)
    }
    .transition(
      .asymmetric(
        insertion: .init(
          .blurReplace.combined(with: .scale).animation(.snappy.delay(1)),
        ),
        removal: .init(
          .blurReplace.combined(with: .scale).animation(.snappy.delay(0.1))
        )
      )
    )
  }
  
  @ViewBuilder
  private func scriptView(
    data: TypingoService.Response,
    step: Int
  ) -> some View {
    let finishedIndex = data.script.count - 1
    let items = data.script.prefix(step)
    let lastIndex = items.count - 1
    
    LazyVStack(alignment: .leading, spacing: 40) {
      ForEach(
        Array(
          items.enumerated()
        ),
        id: \.element
      ) { offset, script in
        VStack(alignment: .leading, spacing: 20) {
          Text(script.speaker)
            .font(.footnote)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
              Capsule()
                .fill(.regularMaterial)
                .stroke(Color(.separator))
            }
          
          Text(script.native)
            .font(.footnote)
            .foregroundStyle(.secondary)
          
          let expired = offset < lastIndex || (phase >= .finished && lastIndex == finishedIndex)
          
          HStack(alignment: .top) {
            Button {
              
            } label: {
              Image(systemName: "play.circle")
                .foregroundStyle(Color.secondary)
                .font(.title)
            }

            TranscriptionView(
              text: script.target,
              appearance: .init(
                font: .preferredFont(
                  forTextStyle: .title1
                ).bold(),
                foregroundColor: Color(.label),
                placeholderColor: expired ? Color(.label) : Color.secondary,
                backgroundColor: Color(.systemBackground),
                accentColor: Color(.label),
                highlightedColor: Color(.systemYellow)
              ),
              isFocused: .init(
                get: { self.phase == .step(offset + 1) },
                set: { _ in }
              ),
              isExpired: expired
            ) {
              if offset == finishedIndex {
                self.phase = .finished
              } else {
                self.phase = .step(offset + 2)
              }
            }
            .disabled(expired)
          }
        }
        .transition(.blurReplace.combined(with: .scale).animation(.snappy.delay(0.2)))
      }
    }
  }
  
  @ViewBuilder
  private func keyExpressionView(data: TypingoService.Response) -> some View {
    LazyVStack(alignment: .leading, spacing: 40) {
      ForEach(data.keyExpressions, id: \.self) { expression in
        VStack(alignment: .leading, spacing: 10) {
          Text(expression.native)
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text(expression.target)
            .font(.title2)
            .fontWeight(.medium)
        }
      }
    }
  }
  
  @ViewBuilder
  private func nextTopicView(data: TypingoService.Response) -> some View {
    Menu {
      ForEach(data.nextTopics, id: \.self) { topic in
        Button {
          category = topic
          restartTypingo()
        } label: {
          Text(topic)
        }
      }
    } label: {
      HStack {
        Text("Next")
      }
      .font(.title2)
      .fontWeight(.bold)
      .italic()
      .foregroundStyle(Color(.label))
      .padding(.horizontal, 14)
      .padding(.vertical, 7)
      .background {
        Capsule()
          .fill(.regularMaterial)
          .stroke(.thickMaterial)
      }
    }
  }
}

extension ContentView {
  private func restartTypingo() {
    phase = .ready
    startTypingo()
  }
  
  private func startTypingo() {
    guard phase == .ready else { return }
    
    phase = .loading
    
    Task { [viewModel] in
      do {
        try await viewModel.reloadScript(
          category: category,
          level: level.rawValue,
          nativeLanguage: nativeLanguage,
          targetLanguage: targetLanguage
        )
        if let data = viewModel.data {
          typingoData = try PropertyListEncoder().encode(data)
        }
      } catch {
        print(error)
      }
      
      phase = .started
      
      try? await Task.sleep(for: .seconds(2))
      
      phase = .step(1)
    }
  }
  
  private func restoreTypingoData() async throws {
    if let typingoData {
      try? await Task.sleep(for: .seconds(2))
      
      let data = try PropertyListDecoder().decode(TypingoService.Response.self, from: typingoData)
      viewModel.data = data
      
      phase = .started
      
      try? await Task.sleep(for: .seconds(2))
      
      phase = .step(1)
    }
  }
}

#Preview {
  ContentView()
}

struct DividerLabel: View {
  var text: String
  
  var body: some View {
    HStack(spacing: 10) {
      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)
      
      Text(text)
        .font(.title2)
        .foregroundStyle(Color(.separator))
      
      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)
    }
  }
}
