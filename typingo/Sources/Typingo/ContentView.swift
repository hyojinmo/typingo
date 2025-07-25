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
  
  @State private var numberOfLessons = 0
  
  @State private var phase: Phase = .none
  @FocusState private var focusStep: Phase?
  
  @AppStorage("OpenAIModel") private var model: OpenAIService.GPTModel = .gpt4oMini
  
  @State private var ttsService = TTSService()
  
  @State private var isPresentedNewTopicView = false
  @State private var isPresentedKeyboardTutorialView = false
  
  @State private var availableDate: Date?
  
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
          
          if phase >= .ready {
            logoView()
          }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
          if phase >= .started {
            HStack {
              Menu {
                Button(role: .destructive) {
                  finishTypingo()
                } label: {
                  Image(systemName: "xmark.octagon.fill")
                  
                  Text("Start over")
                  
                  Text("The current lesson will be canceled.")
                }
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .imageScale(.large)
                  .foregroundStyle(Color(.label))
              }
              
              Spacer()
            }
            .padding(.horizontal, 10)
          }
        }
        
        if phase >= .ready {
          streakView()
          
          if phase == .ready {
            Text("No mic, no problem. Just type to learn.")
              .font(.footnote)
              .italic()
              .multilineTextAlignment(.center)
              .transition(
                .asymmetric(
                  insertion: .init(
                    .blurReplace.animation(.snappy.delay(1.5))
                  ),
                  removal: .init(
                    .blurReplace
                  )
                )
              )
          }
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
              text: data.motivation.speaker
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
            
            motivationView(data: data)
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
            
            DividerLabel(
              text: "🔥"
            )
            .transition(
              .asymmetric(
                insertion: .init(
                  .blurReplace.animation(.snappy.delay(6))
                ),
                removal: .init(
                  .blurReplace
                )
              )
            )
            
            nextTopicView(data: data)
              .id(Phase.finished)
              .transition(
                .asymmetric(
                  insertion: .init(
                    .blurReplace.animation(.snappy.delay(7))
                  ),
                  removal: .init(
                    .blurReplace
                  )
                )
              )
          }
        } else if phase == .ready {
          if let availableDate {
            availableButton(at: availableDate)
          } else {
            startButton()
          }
        } else if phase == .loading {
          progressView()
        }
      }
      .padding()
    }
    .scrollPosition(
      id: .init(
        get: { phase },
        set: { _ in }
      ),
      anchor: .top
    )
    .overlay(alignment: .bottom) {
      if isPresentedNewTopicView {
        TextInputView(
          textIO: .init(
            get: {
              .init(
                title: "New topic",
                text: "") { string in
                  guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                  
                  category = string
                  restartTypingo()
                }
            },
            set: {
              if $0 == nil {
                isPresentedNewTopicView = false
                focusStep = phase
              }
            }
          )
        )
        .transition(.blurReplace)
      }
    }
    .safeAreaInset(edge: .bottom) {
      if let data = viewModel.data {
        if case .step(let step) = focusStep {
          let progress = Double(step) / Double(data.script.count)
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
    }
    .animation(.snappy, value: phase)
    .animation(.snappy, value: focusStep)
    .animation(.snappy, value: viewModel.data)
    .task {
      try? await Task.sleep(for: .seconds(1))
      
      phase = .ready
      
      do {
        try await checkAvailableDate()
        try await restoreTypingoData()
      } catch {
        print(error)
      }
    }
    .task(id: phase) {
      if case .step(let step) = phase,
         step > 0,
         let data = viewModel.data,
         data.script.indices.contains(step - 1)
      {
        try? await Task.sleep(for: .seconds(1))
        
        do {
          let script = data.script[step - 1]
          if AudioDeviceInteractor().isVolumeOn() {
            try await ttsService.speak(
              text: script.target,
              languageCode: data.targetLanguage
            )
          }
        } catch {
          print(error)
        }
      } else if phase == .finished {
        if let data = viewModel.data {
          do {
            let dataSource = UserLessonLocalDataSource()
            try await dataSource.insertUserLesson(
              typingoData: data,
              llmModel: model.rawValue
            )
          } catch {
            print(error)
          }
        }
        typingoData = nil
      }
      focusStep = phase
    }
    .task {
      do {
        let dataSource = UserLessonLocalDataSource()
        numberOfLessons = try await dataSource.countForUserLessons()
        
        for await _ in dataSource.observeChanges() {
          guard !Task.isCancelled else { return }
          numberOfLessons = try await dataSource.countForUserLessons()
        }
      } catch {
        print(error)
      }
    }
    .onChange(of: NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) {
      Task {
        try await checkAvailableDate()
      }
    }
    .sensoryFeedback(.selection, trigger: phase)
    .sheet(isPresented: $isPresentedKeyboardTutorialView) {
      KeyboardTutorialView()
    }
  }
}

extension ContentView {
  @ViewBuilder
  private func menuView() -> some View {
    #if DEBUG
    Section("Models") {
      Menu {
        Picker(
          selection: $model) {
            ForEach([
              OpenAIService.GPTModel.gpt4o,
              .gpt4oMini,
              .gpt41,
              .gpt41mini
            ], id: \.self) { model in
              Button {
                self.model = model
              } label: {
                Text(model.rawValue)
              }
            }
          } label: {
            Text(verbatim: "GPT Models")
          }
      } label: {
        Text(model.rawValue)
      }
    }
    .menuActionDismissBehavior(.disabled)
    #endif
    
    Section("Languages") {
      nativeLanguagePicker()
        .menuActionDismissBehavior(.disabled)
      
      targetLanguagePicker()
    }
    
    Section("Topics") {
      topicPicker()
        .menuActionDismissBehavior(.disabled)
      
      Button {
        isPresentedNewTopicView = true
      } label: {
        Image(systemName: "keyboard")
        
        Text("New topic")
        
        Text("Type any situation to start learning")
      }
    }
    
    Section("Levels") {
      Menu {
        levelPicker()
      } label: {
        Text(level.rawValue)
      }
      .menuActionDismissBehavior(.disabled)
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
          ForEach(
            Languages().targetLanguages().filter(
              {
                $0.languageCode != nativeLanguage
              }
            ),
            id: \.languageCode
          ) { language in
            Text(language.title)
          }
        },
        label: {
          Text("Language to learn")
        }
      )
      .menuActionDismissBehavior(.disabled)
      
      Divider()
      
      Button {
        isPresentedKeyboardTutorialView = true
      } label: {
        Image(systemName: "plus.circle")
        
        Text("Add language")
        
        Text("Would you like to learn another language?")
      }

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
      ForEach(Topics.Category.allCases, id: \.self) { category in
        switch category {
        case .dailyLife:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.DailyLife.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.dailyLife.title)
            }
          } label: {
            Text(Topics.Category.dailyLife.title)
          }
        case .travel:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.Travel.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.travel.title)
            }
          } label: {
            Text(Topics.Category.travel.title)
          }
        case .schoolAndWork:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.SchoolAndWork.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.schoolAndWork.title)
            }
          } label: {
            Text(Topics.Category.schoolAndWork.title)
          }
        case .aboutMeAndPeople:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.AboutMeAndPeople.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.aboutMeAndPeople.title)
            }
          } label: {
            Text(Topics.Category.aboutMeAndPeople.title)
          }
        case .feelingsAndReactions:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.FeelingsAndReactions.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.feelingsAndReactions.title)
            }
          } label: {
            Text(Topics.Category.feelingsAndReactions.title)
          }
        case .funAndInterests:
          Menu {
            Picker(
              selection: $category
            ) {
              ForEach(Topics.FunAndInterests.allCases, id: \.title) { topic in
                Text(topic.title)
              }
            } label: {
              Text(Topics.Category.funAndInterests.title)
            }
          } label: {
            Text(Topics.Category.funAndInterests.title)
          }
        }
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
    HStack(spacing: 2) {
      Text(verbatim: "Typin")
        .font(.largeTitle)
        .fontWeight(.medium)
        .fontDesign(.serif)
        .foregroundStyle(Color.primary)
      
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
      
      Text(verbatim: "go")
        .font(.largeTitle)
        .fontWeight(.medium)
        .fontDesign(.serif)
        .foregroundStyle(Color.secondary)
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
        
        Text(verbatim: "\(numberOfLessons)")
          .font(.largeTitle)
          .fontWeight(.black)
          .italic()
          .contentTransition(.numericText(value: Double(numberOfLessons)))
          .animation(.snappy, value: numberOfLessons)
        
        Image(systemName: "laurel.trailing")
          .font(.largeTitle)
        
        Spacer()
      }
      
      Text("Typing")
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
  }
  
  @ViewBuilder
  private func availableButton(at date: Date) -> some View {
    Menu {
      Text("Sorry, we only offer two lessons per day.")
    } label: {
      VStack {
        Text("Available in")
          .font(.footnote)
          .fontWeight(.medium)
        
        Text(date, style: .timer)
          .font(.largeTitle)
          .fontWeight(.black)
          .monospacedDigit()
          .italic()
      }
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
  }
  
  @ViewBuilder
  private func progressView() -> some View {
    HStack(spacing: 14) {
      ProgressView()
        .progressViewStyle(.circular)
        .controlSize(.mini)
      
      Text(category)
        .multilineTextAlignment(.center)
    }
    .font(.title3)
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
    
    VStack(alignment: .leading, spacing: 40) {
      ForEach(
        Array(
          items.enumerated()
        ),
        id: \.element
      ) {
        offset,
        script in
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
              Task {
                do {
                  try await ttsService.speak(
                    text: script.target,
                    languageCode: data.targetLanguage
                  )
                } catch {
                  print(error)
                }
              }
            } label: {
              Image(systemName: "play.circle")
                .foregroundStyle(Color.secondary)
                .font(.title)
            }

            TranscriptionNormalModeView(
              text: script.target,
              appearance: .init(
                font: .preferredFont(
                  forTextStyle: .title1
                ).bold(),
                foregroundColor: Color(.label),
                placeholderColor: expired ? Color(.label) : Color.secondary,
                backgroundColor: Color(.systemBackground),
                accentColor: Color(.label),
                highlightedColor: Color(.systemYellow),
                allowedTypoColor: Color(.systemYellow),
                allowedTypoBackgroundColor: Color(.systemBackground)
              ),
              offset: offset,
              focusStep: $focusStep,
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
      Section("Next topics") {
        ForEach(data.nextTopics, id: \.self) { topic in
          Button {
            category = topic
            restartTypingo()
          } label: {
            Text(topic)
          }
        }
      }
      
      Section("New topic") {
        Button {
          isPresentedNewTopicView = true
        } label: {
          Image(systemName: "keyboard")
          
          Text("New topic")
          
          Text("Type any situation to start learning")
        }
      }
      
      Divider()
      
      Button {
        finishTypingo()
      } label: {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color(.green), Color(.label))
        
        Text("Finish")
        
        Text("The class is now over.")
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
  
  @ViewBuilder
  private func motivationView(data: TypingoService.Response) -> some View {
    VStack(spacing: 10) {
      Text(data.motivation.native)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      
      Text(data.motivation.target)
        .font(.title2)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
    }
  }
}

extension ContentView {
  private func finishTypingo() {
    phase = .ready
    typingoData = nil
  }
  
  private func restartTypingo() {
    phase = .ready
    startTypingo()
  }
  
  private func startTypingo() {
    guard phase == .ready else { return }
    
    phase = .loading
    
    Task { [viewModel] in
      do {
        try await checkAvailableDate()
        
        let isAvailableToday = availableDate == nil
        
        if isAvailableToday {
          try await viewModel.reloadScript(
            category: category,
            level: level.rawValue,
            nativeLanguage: nativeLanguage,
            targetLanguage: targetLanguage,
            model: model
          )
          if let data = viewModel.data {
            typingoData = try data.encoded()
          }
          
          phase = .started
          
          try? await Task.sleep(for: .seconds(2))
          
          phase = .step(1)
        } else {
          phase = .ready
        }
      } catch {
        print(error)
        
        phase = .ready
      }
    }
  }
  
  private func restoreTypingoData() async throws {
    if let typingoData {
      try? await Task.sleep(for: .seconds(2))
      
      let data = try TypingoService.Response(from: typingoData)
      viewModel.data = data
      
      phase = .started
      
      try? await Task.sleep(for: .seconds(2))
      
      phase = .step(1)
    }
  }
}

extension ContentView {
  private func checkAvailableDate() async throws {
    let dataSource = UserLessonLocalDataSource()
    let numberOfLessonInToday = try await dataSource.countForUserLessons(
      predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
        \UserLessonEntity.createdDate >= Calendar.current.startOfDay(for: Date()),
        \UserLessonEntity.createdDate < Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
      ])
    )
    // 하루에 2강의만 제공
    if numberOfLessonInToday >= 2 {
      availableDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
    } else {
      availableDate = nil
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
