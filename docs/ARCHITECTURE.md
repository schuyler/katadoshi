# Kata Dōshi - Architecture & Design Decisions

**Last Updated:** 2025-11-03

This document captures the key architectural decisions, patterns, and implementation details for the Kata Dōshi project.

---

## Project Structure

```
katadoshi/
├── docs/
│   ├── Kata-Doshi-PRD.md                          # Product Requirements Document
│   ├── Integration-Test-SpeechRecognition.md     # Integration test checklist
│   ├── TODO.md                                    # Actionable task list
│   ├── ARCHITECTURE.md                            # This file
│   ├── DEVELOPMENT.md                             # Development workflows
│   └── SESSION-HISTORY.md                         # Completed work history
│
├── katadoshi/
│   ├── Models/
│   │   ├── Form.swift                             # Form model (Codable, Identifiable)
│   │   └── VoiceCommand.swift                     # 8-case enum + parseCommand()
│   │
│   ├── Services/
│   │   ├── FormStore.swift                        # Persistence layer (UserDefaults)
│   │   ├── TextToSpeechService.swift              # TTS with AVSpeechSynthesizer
│   │   └── SpeechRecognitionService.swift         # Speech recognition + protocol abstraction
│   │
│   ├── Managers/
│   │   ├── PracticeSessionManager.swift           # State machine for practice sessions
│   │   └── PracticeSessionManagerError.swift      # Error types
│   │
│   ├── Views/
│   │   ├── FormsListView.swift                    # Forms list with navigation
│   │   ├── FormEditorView.swift                   # Create/edit forms
│   │   └── PracticeView.swift                     # Practice session UI
│   │
│   ├── ViewModels/
│   │   └── PracticeViewModel.swift                # Practice view state management
│   │
│   ├── Debug/
│   │   └── SpeechTestHarnessView.swift            # Manual testing tool (DEBUG only)
│   │
│   ├── ContentView.swift                          # Main app entry with debug tools
│   └── katadoshiApp.swift                         # App definition
│
├── katadoshiTests/
│   ├── FormModelTests.swift                       # 42 tests
│   ├── FormStoreTests.swift                       # 85 tests
│   ├── TextToSpeechServiceTests.swift             # 69 tests
│   ├── SpeechRecognitionServiceTests.swift        # 43 active + 13 disabled tests
│   ├── PracticeSessionManagerTests.swift          # 70+ tests
│   └── PracticeViewModelTests.swift               # Unit tests for ViewModel
│
└── katadoshiUITests/
    ├── FormsListViewUITests.swift                 # 38 UI tests
    ├── FormEditorViewUITests.swift                # 43 UI tests
    └── PracticeViewUITests.swift                  # UI tests for practice session
```

---

## Key Architectural Decisions

### 1. Protocol Abstraction for SpeechRecognizer

**Problem:** `SFSpeechRecognizer` has failable initializer (`init?(locale:)`), making all mock subclass instances optional and causing cascade unwrapping in tests.

**Solution:** Created protocol abstraction pattern:
- `SpeechRecognizerProtocol` - Abstract interface
- `SpeechRecognizerWrapper` - Production implementation
- `MockSpeechRecognizer` - Pure Swift test mock (no failable init!)

**Benefits:**
- No optional unwrapping in 50+ tests
- Follows existing TextToSpeechService pattern
- Maintains comprehensive unit test coverage

**Files:**
- `katadoshi/Services/SpeechRecognitionService.swift` (protocol + wrapper + service)
- `katadoshiTests/SpeechRecognitionServiceTests.swift` (mock + tests)

### 2. Separation of Concerns: Service vs. Manager

**Key Principle:** SpeechRecognitionService is SIMPLE (recognize commands), PracticeSessionManager is COMPLEX (manage state machine).

**SpeechRecognitionService Responsibilities:**
- Start/stop audio recognition (isListening: Bool)
- Parse transcripts into VoiceCommand enum values
- Report recognized commands via didRecognizeCommand callback
- Handle permission and availability errors

**NOT Responsible For:**
- Session state management (Ready, Speaking, Listening, Paused, Completed)
- Validating which commands are valid in which states
- Coordinating mutual exclusion with TTS

**PracticeSessionManager Responsibilities:**
- Owns state machine (PRD Section 5.4)
- Validates state-command combinations (PRD Section 6.1)
- Coordinates TTS and speech recognition mutual exclusion (PRD Section 5.3)
- Handles timeout behavior (PRD Section 6.2)

**PRD References:**
- Section 5.3: SpeechRecognitionService scope
- Section 5.4: PracticeSessionManager scope
- Section 6.1: Voice command availability by state

### 3. @Observable Pattern for SwiftUI (iOS 17+)

**Decision:** Use `@Observable` macro instead of `ObservableObject` protocol.

**Migration:**
- FormStore: Migrated from `@Published` properties to `@Observable`
- Services: Remain callback-based (no migration needed per design)
- PracticeSessionManager: Uses callbacks (protocol-based architecture preserved)

**Rationale:**
- FormStore is pure state container (perfect for @Observable)
- Services use callbacks for async behavior (appropriate pattern)
- Minimal blast radius (only FormStore changed)
- Zero test failures

### 4. View-ViewModel Pattern for Practice Session

**PracticeViewModel Responsibilities:**
- Bridge callback-based PracticeSessionManager to reactive SwiftUI
- Expose @Observable properties: sessionState, currentMoveIndex, showTimeout, error
- Update FormStore.lastPracticed on every session start
- Handle errors and propagate to view via alerts

**PracticeView Responsibilities:**
- Render state-dependent UI
- Display error alerts
- Manage view lifecycle (dismiss, cleanup)
- **TODO:** Manage screen idle timer

**Separation:**
- ViewModel: Business logic and state
- View: Presentation and lifecycle
- Manager: State machine and service coordination

---

## Critical Implementation Details

### Command Parsing Order

The `parseCommand(from:)` function checks commands in priority order using `contains()`:

```swift
// Note: Check "back" before "go" to handle "go back" phrase correctly
if lowercased.contains("next") { return .next }
else if lowercased.contains("back") { return .back }  // BEFORE "go"
else if lowercased.contains("go") { return .go }
```

**Reason:** "go back" should match `.back` not `.go`

### Mutual Exclusion Enforcement (CRITICAL)

The PracticeSessionManager enforces that TTS and speech recognition **NEVER** run simultaneously.

**State-Based Enforcement:**
- `Speaking` state: TTS runs, speech recognition OFF
- `Listening` state: Speech recognition runs, TTS OFF

**Service Coordination Pattern:**
```swift
private func speakCurrentMove() {
    speechService.stopListening()  // STOP speech first
    resetTimeoutTimer()
    transitionTo(.speaking)
    ttsService.speak(text: currentMove)
}

private func startListening() {
    ttsService.stop()  // STOP TTS first
    transitionTo(.listening)
    speechService.startListening()
    startTimeoutTimer()
}
```

**Callback Chain:**
1. TTS completes → `didFinishSpeaking` callback → `startListening()`
2. Command recognized → `didRecognizeCommand` callback → `handleCommand()` → stops listening → speaks next move

**Tests Verify:**
- `servicesNeverRunSimultaneously` - Checks flags at every state transition
- `speakingStateRunsTTSAndStopsSpeechRecognition` - Verifies Speaking state
- `listeningStateRunsSpeechRecognitionAndStopsTTS` - Verifies Listening state

**Why This Matters:**
If both services run simultaneously, the speech recognizer picks up TTS audio output, creating a feedback loop and command confusion.

### Authorization Testing Strategy

**Challenge:** `SFSpeechRecognizer.authorizationStatus()` is a static method that reads real system state. Cannot be mocked in unit tests.

**Solution:**
- 13 unit tests disabled with `.disabled("Requires integration testing with authorized microphone permission")`
- Tests serve as executable specifications even when disabled
- Manual integration testing via:
  1. Manual test checklist (`docs/Integration-Test-SpeechRecognition.md`)
  2. Interactive test harness (`katadoshi/Debug/SpeechTestHarnessView.swift`)

**Test Harness Usage:**
1. Run app in DEBUG mode
2. Navigate to "Debug Tools" → "Speech Recognition Test Harness"
3. Run test scenarios
4. Change Settings → Microphone permission between tests
5. Observe results in real-time

**Disabled Tests Reference:**
Location: `katadoshiTests/SpeechRecognitionServiceTests.swift`

13 tests disabled (require integration testing on physical device)

---

## UI Design System & Conventions

**Note:** These conventions represent initial design decisions for MVP consistency. All choices are subject to refinement based on implementation experience and user feedback.

### Color System
- **Primary Approach:** Use iOS system colors (`.red`, `.blue`, `.green`, etc.) for semantic consistency
- **Semantic State Colors:**
  - Listening: `.green`
  - Speaking: `.blue`
  - Paused: `.orange`
  - Destructive actions: `.red`

### Typography
- **Dynamic Type:** Use Dynamic Type sizes (`.title`, `.body`, `.caption`) for accessibility
- **Fixed Sizes:** Use PRD-specified point sizes (16pt, 18pt, 24pt) for practice view where readability from distance is critical
- **Type Hierarchy:**
  - Navigation titles: System default
  - Form titles: 18pt bold
  - Practice instructions: 24pt bold
  - Body text: System `.body` style
  - Secondary text: 14pt or `.caption` style

### Spacing & Layout
- **Spacing Scale:** Use multiples of 4/8/16/24/32pt for consistent rhythm
- **Safe Areas:** Respect system safe areas for all views
- **Padding:** Standard 16pt horizontal padding for content, 8pt for compact elements

### Button Styles
- **Primary Actions:** `.borderedProminent` style (e.g., Start/Resume buttons)
- **Secondary Actions:** `.bordered` style
- **Destructive Actions:** `.bordered` with `.destructive` role (outlined red button)
- **Navigation Bar Buttons:** Default `.plain` style (system standard)

### List Presentation
- **FormsListView Style:** `.insetGrouped` for modern, polished appearance
- **Row Content:** Follow system standards for list rows (title, subtitle, chevron, swipe actions)
- **Empty States:** Centered message with subtitle guidance

### Icons & Symbols
- **Icon System:** SF Symbols for all icons (system consistency)

### State Management Pattern
- **Observability:** Use `@Observable` macro for state objects (iOS 17+)
- **View State:** `@State` for local view state
- **Shared State:** `@Environment` for dependency injection

### Navigation Pattern
- **Navigation Container:** `NavigationStack` with path-based navigation (iOS 16+)
- **Dismissal:** `@Environment(\.dismiss)` for programmatic view dismissal

### Error Presentation
- **Validation Errors:** `.alert(error:)` modifier with error binding
- **Permission Errors:** Alert with Settings link
- **Inline Errors:** Below form fields where contextually appropriate

### Accessibility
- **Dynamic Type:** Support system text sizing throughout
- **VoiceOver:** Semantic labels for all interactive elements
- **Contrast:** Follow system color adaptations for dark mode and high contrast

---

## Test Coverage Strategy

### Coverage Summary
- **Total Tests:** 350+ tests (estimated, includes all UI layer tests)
- **Passing:** All runnable tests passing
- **Disabled:** 13 tests (SpeechRecognitionService authorization - require integration testing)
- **Coverage:**
  - 100% on business logic (data layer, service layer, manager layer)
  - Comprehensive UI tests for FormsListView, FormEditorView, PracticeView
  - Unit tests for PracticeViewModel

### Test File Organization
- Tests split into focused files (500-1000 lines each)
- Keeps context windows manageable for AI-assisted development
- Each test file focuses on single component

---

## Key Files Reference

### PRD and Documentation
- **PRD:** `docs/Kata-Doshi-PRD.md` - Complete product requirements (v1.2)
- **Integration Tests:** `docs/Integration-Test-SpeechRecognition.md` - Manual test procedures
- **Project Instructions:** `CLAUDE.md` - Build commands, architecture, TDD workflow

### Implementation Files
- **Data Layer:**
  - `katadoshi/Models/Form.swift` - Form model
  - `katadoshi/Services/FormStore.swift` - Persistence

- **Service Layer:**
  - `katadoshi/Services/TextToSpeechService.swift` - TTS service
  - `katadoshi/Services/SpeechRecognitionService.swift` - Speech recognition
  - `katadoshi/Models/VoiceCommand.swift` - Command enum + parsing

- **Manager Layer:**
  - `katadoshi/Managers/PracticeSessionManager.swift` - State machine
  - `katadoshi/Managers/PracticeSessionManagerError.swift` - Error types

- **UI Layer:**
  - `katadoshi/Views/FormsListView.swift` - Forms list view
  - `katadoshi/Views/FormEditorView.swift` - Form editor view
  - `katadoshi/Views/PracticeView.swift` - Practice session view
  - `katadoshi/ViewModels/PracticeViewModel.swift` - Practice view model

- **Test Files:**
  - `katadoshiTests/FormModelTests.swift` - Form model tests
  - `katadoshiTests/FormStoreTests.swift` - FormStore tests
  - `katadoshiTests/TextToSpeechServiceTests.swift` - TTS tests
  - `katadoshiTests/SpeechRecognitionServiceTests.swift` - Speech recognition tests
  - `katadoshiTests/PracticeSessionManagerTests.swift` - Manager tests
  - `katadoshiTests/PracticeViewModelTests.swift` - ViewModel tests
  - `katadoshiUITests/FormsListViewUITests.swift` - FormsListView UI tests
  - `katadoshiUITests/FormEditorViewUITests.swift` - FormEditorView UI tests
  - `katadoshiUITests/PracticeViewUITests.swift` - PracticeView UI tests

- **Debug Tools:**
  - `katadoshi/Debug/SpeechTestHarnessView.swift` - Interactive testing (DEBUG only)

---

**End of Architecture Document**
