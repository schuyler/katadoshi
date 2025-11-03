# Kata Dōshi - Development TODO

**Last Updated:** 2025-11-03
**Current Phase:** Phase 1 MVP - UI Layer Implementation
**Status:** FormsListView and FormEditorView complete. Ready to implement PracticeView.

---

## Current Todo List

### Immediate Next Steps

1. **[✓] Update Xcode project to iOS 17.0 deployment target**
   - ✓ Updated project.pbxproj deployment target (4 occurrences)
   - ✓ Verified build succeeds with new target

2. **[✓] Migrate to @Observable pattern (iOS 17+)**
   - ✓ Migrated FormStore from ObservableObject to @Observable
   - ✓ Updated FormStore tests (removed obsolete test, updated comments)
   - ✓ All 309+ tests passing
   - Note: Services and PracticeSessionManager use callbacks by design (no migration needed per Groucho's recommendation)

3. **[✓] Implement FormsListView**
   - ✓ Location: `katadoshi/Views/FormsListView.swift`
   - ✓ PRD Reference: Sections 7.1, 9.1, 9.4
   - ✓ Design: `.insetGrouped` list, `NavigationStack`, SF Symbols
   - ✓ 38 UI tests + comprehensive unit tests
   - Note: UI test data injection helper needs implementation (minor)

4. **[✓] Implement FormEditorView**
   - ✓ Location: `katadoshi/Views/FormEditorView.swift`
   - ✓ PRD Reference: Sections 7.2, 9.2, 9.4
   - ✓ Design: `.bordered` + `.destructive` delete button, validation alerts
   - ✓ Features: Create/edit modes, TextEditor placeholder, swipe-to-edit navigation
   - ✓ 1 unit test + 43 UI tests (comprehensive coverage)

5. **[ ] Implement PracticeView**
   - Location: `katadoshi/Views/PracticeView.swift`
   - PRD Reference: Sections 7.3, 9.3, 9.4
   - Design: State-dependent UI, `.borderedProminent` buttons, system colors

### Future Work

1. **[ ] Integration tests for SpeechRecognitionService authorization**
   - Manual test checklist created: `docs/Integration-Test-SpeechRecognition.md`
   - Test harness implemented: `katadoshi/Debug/SpeechTestHarnessView.swift`
   - Run 8 test cases on physical device with various permission states
   - Document results in test execution log

---

## Completed ✓

### Phase 1 MVP Components

#### Data Layer
- **[✓] Form Model** (`katadoshi/Models/Form.swift`)
  - Codable, Identifiable, Equatable
  - Properties: id, title, moves, dateCreated, lastPracticed
  - 42 tests passing

- **[✓] FormStore** (`katadoshi/Services/FormStore.swift`)
  - UserDefaults persistence with JSON serialization
  - CRUD operations: loadForms(), saveForm(), updateForm(), deleteForm()
  - Move parsing with validation (PRD Section 4.2)
  - 85 tests passing

#### Service Layer
- **[✓] TextToSpeechService** (`katadoshi/Services/TextToSpeechService.swift`)
  - AVSpeechSynthesizer integration
  - Protocol-based design for testability
  - Methods: speak(), stop(), pause()
  - Completion callbacks via didFinishSpeaking
  - 69 tests passing

- **[✓] SpeechRecognitionService** (`katadoshi/Services/SpeechRecognitionService.swift`)
  - Apple Speech Framework integration (SFSpeechRecognizer, AVAudioEngine)
  - **Protocol abstraction pattern** for testability (key architectural decision)
  - VoiceCommand enum with 8 commands: start, begin, next, go, back, repeat, stop, pause
  - Pure parsing function: `parseCommand(from:)` for unit testing
  - Dependency injection with default initializer
  - Error callbacks: onPermissionDenied, onRecognitionUnavailable
  - 43 unit tests passing + 13 disabled (require integration testing)

- **[✓] VoiceCommand Enum** (`katadoshi/Models/VoiceCommand.swift`)
  - 8 command cases (PRD Section 5.3)
  - Pure parsing function extractable for testing
  - Command priority order: check "back" before "go" (handles "go back" phrase)

#### Manager Layer
- **[✓] PracticeSessionManager** (`katadoshi/Managers/PracticeSessionManager.swift`)
  - State machine with 5 states: Ready, Speaking, Listening, Paused, Completed
  - Protocol-based abstraction (PracticeSessionManagerProtocol)
  - Service coordination enforcing mutual exclusion between TTS and speech recognition
  - Command-state validation matrix (PRD Section 6.1)
  - Navigation methods: moveNext(), movePrevious(), repeatCurrent()
  - 2-minute timeout handling with internal handleTimeout() for testing
  - Callback system: onStateChanged, onMoveChanged, onTimeout, onError, onExit
  - 70+ tests passing (100% state machine coverage)

- **[✓] PracticeSessionManagerError** (`katadoshi/Managers/PracticeSessionManagerError.swift`)
  - Error enum with 4 cases: emptyForm, invalidMoveIndex, serviceUnavailable, permissionDenied
  - Conforms to Error, Equatable, CustomStringConvertible
  - Meaningful error descriptions for user feedback

#### UI Layer
- **[✓] FormsListView** (`katadoshi/Views/FormsListView.swift`)
  - NavigationStack with `.insetGrouped` list style
  - @Observable FormStore integration
  - Form rows display title (18pt bold) and last practiced date (14pt gray)
  - Swipe-to-delete and swipe-to-edit functionality
  - Context menu for Edit action (secondary access)
  - Empty state with "No Forms Yet" message
  - Navigation to FormEditorView (modal sheet) and PracticeView (push)
  - 38 UI tests passing + comprehensive unit tests
  - Test files: `FormsListViewTests.swift`, `FormsListViewUITests.swift`

- **[✓] FormEditorView** (`katadoshi/Views/FormEditorView.swift`)
  - Two modes: `.create` and `.edit(Form)`
  - @Environment(FormStore.self) and @Environment(\.dismiss) integration
  - Title TextField with "Form Name" placeholder
  - Moves TextEditor with custom placeholder overlay ("Enter moves, one per line")
  - Monospace font for moves editor (120pt min height)
  - Save button (.borderedProminent, disabled when inputs empty)
  - Cancel button (.plain navigation bar style)
  - Delete button (.bordered .destructive, edit mode only, confirmation alert)
  - Error handling via alert with FormStoreError descriptions
  - Accessibility labels on all interactive elements
  - 1 unit test + 43 UI tests
  - Test files: `FormEditorViewTests.swift`, `FormEditorViewUITests.swift`

#### iOS 17 Migration
- **[✓] Deployment Target Update**
  - Updated `katadoshi.xcodeproj/project.pbxproj` to iOS 17.0 (4 occurrences)
  - Verified build succeeds with new target

- **[✓] FormStore @Observable Migration**
  - Migrated FormStore from `ObservableObject` to `@Observable` macro
  - Removed `@Published` wrapper (properties now implicitly observable)
  - Updated FormStore tests (removed obsolete `formStoreIsObservableObject` test)
  - Updated test comments to reference @Observable instead of ObservableObject
  - All 309+ tests passing (84 FormStore tests)

- **[✓] Conservative Approach (per Groucho's recommendation)**
  - Services and PracticeSessionManager use callbacks by design (no migration needed)
  - Protocol-based architecture preserved (testability maintained)
  - Minimal blast radius (only FormStore changed)
  - Zero test failures

#### Testing Infrastructure
- **[✓] Integration Test Checklist** (`docs/Integration-Test-SpeechRecognition.md`)
  - 8 comprehensive test cases for authorization flows
  - Test execution log template
  - Troubleshooting guide

- **[✓] Debug Test Harness** (`katadoshi/Debug/SpeechTestHarnessView.swift`)
  - Interactive manual testing for speech recognition
  - Real-time authorization status
  - Visual pass/fail results
  - Accessible via ContentView → Debug Tools (DEBUG builds only)

#### Project Infrastructure
- **[✓] Test File Organization**
  - Split monolithic test file into focused files:
    - `FormModelTests.swift` (42 tests)
    - `FormStoreTests.swift` (85 tests)
    - `TextToSpeechServiceTests.swift` (69 tests)
    - `SpeechRecognitionServiceTests.swift` (43 tests)
    - `PracticeSessionManagerTests.swift` (70+ tests)

- **[✓] Updated ContentView**
  - Navigation structure
  - Phase progress display
  - Debug tools section (DEBUG only)

### Test Coverage Summary
- **Total Tests:** 309+ tests
- **Passing:** 309+ tests (100% of runnable tests)
- **Disabled:** 13 tests (SpeechRecognitionService authorization - require integration testing)
- **Coverage:** 100% on business logic (data layer, service layer, manager layer)

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

**Reference:** See Groucho's architectural analysis in session notes

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

**PracticeSessionManager Responsibilities (IMPLEMENTED):**
- Owns state machine (PRD Section 5.4) ✓
- Validates state-command combinations (PRD Section 6.1) ✓
- Coordinates TTS and speech recognition mutual exclusion (PRD Section 5.3) ✓
- Handles timeout behavior (PRD Section 6.2) ✓

**PRD References:**
- Section 5.3: SpeechRecognitionService scope
- Section 5.4: PracticeSessionManager scope
- Section 6.1: Voice command availability by state

### 3. TDD Workflow with Agent Collaboration

**Process:**
1. **Groucho** (Technical Planning) - Proposes architecture based on existing patterns
2. **Zeppo** (Test Design) - Writes comprehensive unit tests
3. **Chico** (Test Review) - Critiques tests for correctness and PRD alignment
4. **Zeppo ↔ Chico** (Iteration) - Refine tests until both agree
5. **Implementation** - Write code to pass all tests
6. **Chico** (Code Review) - Review implementation
7. **Issue Resolution** - Fix critical/important issues

**Example:** SpeechRecognitionService went through 3 test iterations to resolve architectural mismatch (tests initially assumed service owned state management, but PRD Section 5.4 assigns that to PracticeSessionManager).

### 4. Parallel Implementation with Duck Agents

**Pattern:** For multi-file features, use parallel duck agents (nicknamed Huey, Dewey, Louie) to implement different files simultaneously.

**PracticeSessionManager Example:**
- **Huey**: Implemented `PracticeSessionManagerError.swift` (error enum)
- **Dewey**: Implemented `PracticeSessionManager.swift` (state machine)
- Executed in parallel using single message with multiple Task tool calls
- Both completed simultaneously, reducing implementation time

**Benefits:**
- Faster implementation for independent modules
- Consistent code quality (both agents follow same patterns)
- Reduces total session time

**When to Use:**
- Multi-file features with clear module boundaries
- Files with minimal inter-dependencies
- When tests are already written (guides implementation)

**When NOT to Use:**
- Single-file changes
- Tightly coupled logic requiring coordination
- Exploratory work where approach is uncertain

**Bug Fixes Applied:**
After parallel implementation, systematic debugging revealed:
1. `start()` method signature mismatch (not throwing)
2. Command callback not processing commands
3. `moveNext()` index bounds issue on completion
4. Error descriptions case sensitivity

All fixed through iterative review with Chico analyzing failures.

---

## Important Implementation Notes

### Command Parsing Order Matters

The `parseCommand(from:)` function checks commands in priority order using `contains()`:

```swift
// Note: Check "back" before "go" to handle "go back" phrase correctly
if lowercased.contains("next") { return .next }
else if lowercased.contains("back") { return .back }  // BEFORE "go"
else if lowercased.contains("go") { return .go }
```

**Reason:** "go back" should match `.back` not `.go`

### Mutual Exclusion Enforcement (CRITICAL)

The PracticeSessionManager enforces that TTS and speech recognition **NEVER** run simultaneously. This is implemented through:

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

### Disabled Tests Reference

Location: `katadoshiTests/SpeechRecognitionServiceTests.swift`

Disabled tests (require integration testing):
- `startListeningMethodStartsAudioEngine()`
- `startListeningCanBeCalledMultipleTimes()`
- `startListeningSetsIsListeningToTrue()`
- `stopListeningMethodStopsAudioEngine()`
- `stopListeningSetsIsListeningToFalse()`
- `isListeningReturnsTrueWhenListening()`
- `serviceDoesNotStartWhenRecognizerUnavailable()`
- `handlesAudioEngineErrors()`
- `handlesRecognitionTaskErrors()`
- `serviceAcceptsCustomRecognizerViaInitializer()`
- `serviceAcceptsCustomAudioEngineViaInitializer()`
- `supportsMutualExclusionWithTTS()`
- `parseCommandRecognizesCommandsInPhrases()` (was failing, now passes after reordering)

---

## Project Structure

```
katadoshi/
├── docs/
│   ├── Kata-Doshi-PRD.md                          # Product Requirements Document
│   ├── Integration-Test-SpeechRecognition.md     # Integration test checklist
│   └── TODO.md                                    # This file
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
│   ├── Views/                                     # To be implemented
│   │   ├── FormsListView.swift                    # TODO: Forms list with navigation
│   │   ├── FormEditorView.swift                   # TODO: Create/edit forms
│   │   └── PracticeView.swift                     # TODO: Practice session UI
│   │
│   ├── Debug/
│   │   └── SpeechTestHarnessView.swift            # Manual testing tool (DEBUG only)
│   │
│   ├── ContentView.swift                          # Main app entry with debug tools
│   └── katadoshiApp.swift                         # App definition
│
└── katadoshiTests/
    ├── FormModelTests.swift                       # 42 tests
    ├── FormStoreTests.swift                       # 85 tests
    ├── TextToSpeechServiceTests.swift             # 69 tests
    └── SpeechRecognitionServiceTests.swift        # 43 active + 13 disabled tests
```

---

## Key Files Reference

### PRD and Documentation
- **PRD:** `docs/Kata-Doshi-PRD.md` - Complete product requirements
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

- **Test Files:**
  - `katadoshiTests/FormModelTests.swift` - Form model tests
  - `katadoshiTests/FormStoreTests.swift` - FormStore tests
  - `katadoshiTests/TextToSpeechServiceTests.swift` - TTS tests
  - `katadoshiTests/SpeechRecognitionServiceTests.swift` - Speech recognition tests

- **Debug Tools:**
  - `katadoshi/Debug/SpeechTestHarnessView.swift` - Interactive testing (DEBUG only)

### Build Commands

**Build:**
```bash
xcodebuild -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Run all tests:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Run specific test suite:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:katadoshiTests/SpeechRecognitionServiceTests
```

---

## Next Steps Context

### PracticeSessionManager Implementation

**Before starting implementation:**
1. Review PRD Section 5.4 (PracticeSessionManager scope)
2. Review PRD Section 6.1 (Voice command availability by state)
3. Review PRD Section 6.2 (Timeout behavior)
4. Follow TDD workflow: Groucho → Zeppo → Chico → Implementation

**Key Requirements:**
- State machine with 5 states
- State transitions controlled by voice commands and TTS completion
- Mutual exclusion: TTS and speech recognition never run simultaneously
- Timeout: After 2 minutes of no input, show prompt but continue listening
- Command validation: Only accept valid commands for current state

**State Machine:**
```
Ready → Speaking → Listening → Speaking (loop) OR Paused OR Completed
        ↓
        Paused → Speaking (resume)
```

**Command-State Matrix (PRD Section 6.1):**
- Ready: start, begin
- Speaking: stop (only)
- Listening: next, go, back, repeat, pause, stop
- Paused: start, begin, stop
- Completed: (practice ended)

**Integration Points:**
- Uses TextToSpeechService (completed)
- Uses SpeechRecognitionService (completed)
- Uses FormStore to load form data (completed)
- Provides interface for PracticeView (to be implemented)

---

## Notes for Future Sessions

### Context from This Session

1. **Protocol Abstraction Pattern Established**
   - Proved successful for testing Apple frameworks with failable initializers
   - Pattern can be reused for other Apple framework integrations
   - Groucho validated this approach as consistent with project patterns

2. **Integration Testing Strategy**
   - Manual testing for system-level behavior (permissions)
   - Unit testing for business logic (parsing, state management)
   - Test harness for developer verification
   - Clear separation of concerns

3. **TDD Workflow Validated**
   - Zeppo/Chico iteration caught architectural mismatch early
   - Tests serve as executable specifications
   - Protocol-based design emerged from testability requirements

4. **Code Organization**
   - Tests split into focused files (500-1000 lines each)
   - Keeps context windows manageable for AI-assisted development
   - Each test file focuses on single component

### Questions to Consider

1. **PracticeSessionManager Testability**
   - Should we extract state machine logic into pure functions?
   - How to test TTS/SR coordination without integration tests?
   - Mock strategy for services that PracticeSessionManager depends on?

2. **UI Implementation**
   - SwiftUI architecture pattern (MVVM, TCA, etc.)?
   - Where to place state management (@State, @StateObject, @Observable)?
   - How to test SwiftUI views?

3. **Phase 2 Planning**
   - When to implement timed mode (PRD Phase 2)?
   - Statistics tracking architecture?
   - Export/import format for forms?

---

## Git Commit Messages Reference

Recent commits follow this pattern:

```
Implement Phase 1 MVP: [Component] with [details]

[Component Layer]:
- Feature 1
- Feature 2
- Feature 3

Test Coverage:
- X tests passing
- Uses [testing framework]
- [Coverage details]

[Additional context]
```

Example:
```
Implement SpeechRecognitionService with protocol abstraction pattern

Service Layer:
- SpeechRecognizerProtocol abstracting Apple Speech Framework
- SpeechRecognizerWrapper for production use
- Pure parseCommand() function for testability
- Error callbacks for permission and availability

Test Coverage:
- 43 unit tests passing (100% business logic)
- 13 tests disabled (require integration testing)
- Protocol-based mocks eliminate optional unwrapping

Integration Testing:
- Manual test checklist in docs/
- Interactive test harness in Debug/

All enabled tests passing. Ready for PracticeSessionManager.
```

---

## Session Recovery Checklist

If starting a new session:

1. **[ ] Read PRD** (`docs/Kata-Doshi-PRD.md`) - Understand product requirements
2. **[ ] Read TODO** (`docs/TODO.md`) - This file, understand current state
3. **[ ] Read CLAUDE.md** - Build commands, architecture, TDD workflow
4. **[ ] Run all tests** - Verify current state (should be 309+ passing, 13 disabled)
5. **[ ] Review integration test docs** - Understand testing strategy
6. **[ ] Check next todo item** - Start with UI layer (FormsListView, FormEditorView, PracticeView)

**Current State Verification:**
```bash
# Should show 309+ passing tests
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Recent Session Notes (2025-11-03)

### PracticeSessionManager Implementation

**Workflow Used:** TDD with parallel implementation
1. Groucho created technical plan (state machine architecture)
2. Zeppo wrote 70+ comprehensive tests
3. Chico reviewed tests (identified 5 critical issues)
4. Zeppo revised tests based on feedback
5. Chico approved revised tests
6. Groucho clarified design questions (non-throwing init, internal handleTimeout)
7. **Huey & Dewey implemented in parallel** (error enum + manager class)
8. Fixed bugs identified by Chico:
   - `start()` throws on empty form
   - Command callback processes commands
   - `moveNext()` keeps index in bounds
   - Error descriptions use lowercase

**Result:** 70+ tests passing, all state machine requirements met

**Key Learnings:**
- Parallel implementation with duck agents effective for multi-file features
- Critical to verify protocol signatures match between implementation and tests
- Chico's analysis crucial for identifying subtle bugs (callback not processing commands)
- Index bounds management critical in state machines

**Files Created:**
- `katadoshi/Managers/PracticeSessionManager.swift`
- `katadoshi/Managers/PracticeSessionManagerError.swift`
- `katadoshiTests/PracticeSessionManagerTests.swift`

**Commit:** `a35c2a0` - "Implement PracticeSessionManager state machine with comprehensive tests"

---

**End of TODO Document**

Ready to proceed with UI layer implementation (FormsListView, FormEditorView, PracticeView).
