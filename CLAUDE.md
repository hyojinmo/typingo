# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Typingo is an iOS language learning app built with SwiftUI. Users practice typing/transcription in a target language by listening to AI-generated scripts via TTS and typing what they hear. Content is generated on-demand using the OpenAI API.

## Build & Run

- **Xcode project:** `typingo.xcodeproj` (single target: `typingo`)
- **Minimum deployment:** iOS 18.0
- **Build configurations:** Debug, Release
- **Dependencies:** Swift Package Manager (Firebase iOS SDK)
- **Build from CLI:** `xcodebuild -project typingo.xcodeproj -scheme typingo -sdk iphonesimulator build`
- **No test target exists** — there are no unit or UI tests

### Secrets

The OpenAI API key lives in `typingo/Supporting Files/Secret.xcconfig` (gitignored). It's included via `App.xcconfig` and exposed through `Info.plist` as `OPEN_AI_SECRET`. In CI (Xcode Cloud), `ci_scripts/ci_pre_xcodebuild.sh` generates `Secret.xcconfig` from the `OPEN_AI_SECRET` environment variable.

## Architecture

### Source layout (`typingo/Sources/`)

| Directory | Purpose |
|---|---|
| `App/` | App entry point (`typingoApp`), `SceneDelegate`, `AppConfiguration` global actor |
| `Typingo/` | Feature UI — `ContentView` (main orchestrator), `Transcription/`, `TTS/`, `NewTopic/`, `Tutorial/` |
| `Typingo/Foundation/` | View model (`TypingoViewModel`), enums for `Topics`, `Levels`, `Languages` |
| `Service/OpenAI/` | `OpenAIService` — raw HTTP client for the OpenAI chat completions API |
| `Service/Typingo/` | `TypingoService` — domain service that builds prompts and parses typed responses |
| `Service/` | `JSONSchemaRepresentable` — protocol for generating JSON schemas from Swift types (used for OpenAI structured outputs) |
| `Data/CoreDataStack/` | CoreData setup with `Mutex`-based thread safety, versioned schema, type-safe `NSPredicate` extensions |
| `Data/LocalDataSource/` | `UserLessonLocalDataSource` — persists lesson history |
| `Foundation/` | Shared extensions (`String`, `UIFont`, `UniquedSequence`) and `AudioDeviceInteractor` |

### Data flow

1. User selects category/level/languages → `TypingoViewModel.reloadScript()`
2. `TypingoService.fetchScript()` builds a system prompt and calls `OpenAIService.chat<T>()`
3. OpenAI returns JSON conforming to `TypingoService.Response` (enforced via JSON schema structured output)
4. `ContentView` uses a phase-based state machine (`ContentView.Phase`) to walk the user through the exercise

### Key patterns

- **`@globalActor AppConfiguration`** — singleton actor holding `CoreDataManager`; thread-safe app-wide state
- **`@Observable`** view models (`TypingoViewModel`, `TTSService`) — not `@StateObject`
- **`Sendable` everywhere** — all service structs and models are `Sendable`
- **`async/await`** for all async work; no completion handlers
- **`JSONSchemaRepresentable`** — reflection-based protocol that generates JSON schemas from Swift types for OpenAI structured outputs
- **`Mutex`** — used in `CoreDataStack` for thread-safe `NSPersistentContainer` access
- **`@AppStorage`** — user preferences (category, level, source/target language, GPT model)
- **Firebase Analytics/Crashlytics** — initialized only in `RELEASE` builds
