# Kata Dōshi - Product Requirements Document

**Version:** 1.1
**Date:** November 3, 2025
**Status:** MVP Specification

---

## 1. Product Overview

### 1.1 Product Name
**Kata Dōshi** (形同士) - "Form Companion"

### 1.2 Product Vision
Kata Dōshi is a voice-controlled mobile application that helps martial artists practice forms (kata) by providing step-by-step audio instructions, allowing practitioners to focus on execution rather than memorizing sequences.

### 1.3 Target Platform
- **MVP:** iOS (native, Swift/SwiftUI)
- **Future:** Android (contingent on MVP success and demand)

### 1.4 Core Value Proposition
Enables martial artists to practice forms independently by solving the fundamental problem: "I can never remember which step comes next."

---

## 2. Problem Statement

### 2.1 User Problem
Martial arts practitioners struggle to remember the complete sequence of moves in forms (kata), especially when learning new forms or practicing less frequently performed forms. This interrupts practice flow and reduces training effectiveness.

### 2.2 Current Solutions & Limitations
- **Written notes:** Requires stopping practice to read
- **Video playback:** Must look at screen, can't follow along physically
- **Training partners:** Not always available
- **Memory alone:** Leads to frustration and incorrect practice

### 2.3 Our Solution
A hands-free, voice-controlled app that reads each move aloud and waits for the user's command before proceeding, enabling seamless practice flow.

---

## 3. User Stories

### 3.1 Primary User Stories (MVP)
1. As a martial artist, I want to load my form's move list so I can practice with audio guidance.
2. As a practitioner, I want to hear each move read aloud so I know what to do next.
3. As a user, I want to control the pace with voice commands so I can move at my own speed.
4. As a student, I want to go back and repeat moves so I can practice difficult sections.
5. As a user, I want to edit my forms so I can correct mistakes or update techniques.

### 3.2 Future User Stories
1. As a practitioner, I want timed mode so I can practice at performance speed.
2. As a user, I want to practice with my screen off so I can save battery during long sessions.
3. As a student, I want to track my practice history so I can see my progress.
4. As a user, I want to jump to specific moves so I can practice particular sections.

---

## 4. Features & Requirements

### 4.1 MVP Features (Phase 1)

#### 4.1.1 Form Management
- Create new forms with title and move list
- Edit existing forms
- Delete forms
- View list of all saved forms
- Simple text-based input (supports copy/paste)

#### 4.1.2 Voice-Controlled Practice
- Step-by-step audio instruction reading
- Voice command recognition
- Visual display of current position
- Manual stop button

#### 4.1.3 Basic Navigation
- Move forward through form
- Move backward through form
- Repeat current instruction
- Pause and resume session
- Stop session

### 4.2 Future Features (Post-MVP)
- Timed auto-advance mode
- Screen-off operation
- Practice statistics and tracking
- Jump to specific move number
- Voice and speed customization
- Form categories/organization
- Export/import forms
- Android version

---

## 5. Technical Architecture

### 5.1 Architecture Overview
Three-layer architecture:
1. **Data Layer:** Form storage and retrieval
2. **Service Layer:** Voice recognition and text-to-speech
3. **UI Layer:** SwiftUI views

### 5.2 Data Layer

#### Form Model
```
Form {
  id: UUID
  title: String
  moves: [String]
  dateCreated: Date
  lastPracticed: Date  // Updated when practice session starts
}
```

#### FormStore
- **Persistence:** UserDefaults (JSON serialization)
- **Methods:**
  - loadForms() -> [Form]
  - saveForm(form: Form)
  - updateForm(form: Form)
  - deleteForm(id: UUID)

#### Form Parsing Rules
- Split input on newlines
- Trim whitespace from each line
- Skip empty lines
- Reject lines longer than 200 characters
- Minimum 1 move required to save form

### 5.3 Service Layer

#### SpeechRecognitionService
- **Framework:** Apple Speech Framework
- **Recognized Commands:**
  - "start" / "begin"
  - "next" / "go"
  - "back"
  - "repeat"
  - "stop"
  - "pause"
- **Behavior:**
  - Start listening only after TTS completes
  - Stop immediately upon recognizing valid command
  - Ignore unrecognized input (continue listening)
  - Must not run simultaneously with TTS

#### TextToSpeechService
- **Framework:** AVSpeechSynthesizer
- **Methods:**
  - speak(text: String)
  - stop()
  - pause()
- **Configuration:** Default voice and speed for MVP
- **Behavior:** Must complete before voice recognition starts

#### Critical Coordination Rule
SpeechRecognitionService and TextToSpeechService are **mutually exclusive**:
- TTS must stop before SpeechRecognition starts
- SpeechRecognition must stop before TTS speaks
- PracticeSessionManager enforces this ordering

### 5.4 Practice Session Management

#### PracticeSessionManager
State machine controlling practice flow with the following states:

**States:**
1. **Ready** - Waiting for "start" command or button press
2. **Speaking** - TTS reading instruction (voice recognition OFF)
3. **Listening** - Waiting for voice command (TTS OFF)
4. **Paused** - Session paused, can resume
5. **Completed** - All moves finished

**State Transitions:**
- Ready → Speaking: On "start"/"begin" command or start button press
- Speaking → Listening: When TTS completes reading
- Listening → Speaking: On valid navigation command
- Listening → Listening: On 2-minute timeout (with visual prompt)
- Any state → Ready: On "stop" command or stop button
- Listening → Paused: On "pause" command
- Paused → Speaking: On "start" command or button

**Properties:**
- currentForm: Form
- currentMoveIndex: Int
- state: SessionState

**Methods:**
- start()
- handleCommand(command: VoiceCommand)
- moveNext()
- movePrevious()
- repeatCurrent()
- pause()
- stop()

### 5.5 UI Layer (SwiftUI)

#### FormsListView
- Displays all saved forms as scrollable list
- Each item shows form title
- Tap form to start practice session
- Navigation to FormEditorView (new or edit)
- Swipe to delete form

#### FormEditorView
- Text field for form title (required)
- Multi-line text editor for moves
- One move per line
- Save button (validates before saving)
- Cancel button
- Delete button (for existing forms)
- Automatic paste support

#### PracticeView
**Always Visible Elements:**
- Move counter: "Move X of Y"
- Current instruction text (large, readable)
- Stop button (red, prominent, bottom of screen)

**State-Dependent Elements:**
- **Ready State:**
  - "Say 'start' or press Start to begin" prompt
  - Start button
  - First instruction displayed
  
- **Listening State:**
  - "Listening..." indicator
  - Current instruction
  
- **Speaking State:**
  - "Speaking..." indicator
  - Current instruction

- **Timeout State (after 2 minutes):**
  - "Still there? Say 'next' to continue" prompt
  - Continues listening (doesn't stop session)
  - Prompt disappears when valid command received

- **Paused State:**
  - "Paused" indicator
  - "Say 'start' to resume" prompt
  - Resume button

- **Completed State:**
  - "Form Complete!" message
  - "Say 'start' or 'begin' to restart" prompt
  - Session remains in Completed state (no automatic exit)
  - Start/Begin button visible
  - Saying "start"/"begin" or pressing button restarts form from first move

---

## 6. Voice Commands Specification

### 6.1 Command Behaviors

#### "Start" / "Begin"
- **Available in:** Ready state, Paused state, Completed state
- **Action:** Begin reading first move (from Ready), resume from current move (from Paused), or restart form from beginning (from Completed)
- **Transition:** → Speaking state

#### "Next" / "Go"
- **Available in:** Listening state
- **Action:** Advance to next move and read it
- **Special case:** At last move, transition to Completed state
- **Transition:** → Speaking state

#### "Back"
- **Available in:** Listening state
- **Action:** Move to previous instruction, read it
- **Special case:** At first move, re-read the first move (same behavior as "Repeat")
- **Transition:** → Speaking state

#### "Repeat"
- **Available in:** Listening state
- **Action:** Stay at current instruction, read it again
- **Difference from "Back":** Does not change position
- **Transition:** → Speaking state

#### "Stop"
- **Available in:** Any state
- **Action:** Exit practice session, return to forms list
- **Transition:** → Exit PracticeView

#### "Pause"
- **Available in:** Listening state
- **Action:** Enter paused state, stop listening
- **Transition:** → Paused state

### 6.2 Unrecognized Commands
- App continues listening
- No error message or feedback
- Optional: Show brief visual indicator "Didn't catch that"

### 6.3 Timeout Behavior
- After 2 minutes of listening with no valid command:
  - Show visual prompt: "Still there? Say 'next' to continue"
  - Continue listening (don't stop session)
  - Prompt disappears when valid command received

---

## 7. Data Flow

### 7.1 Practice Session Flow
1. User selects form from FormsListView
2. App navigates to PracticeView with selected form
3. PracticeSessionManager initializes with form data
4. Display shows first instruction in Ready state
5. User says "start" or presses Start button
6. TextToSpeechService reads first instruction
7. SpeechRecognitionService starts listening
8. User says command → recognized by SpeechRecognitionService
9. Command passed to PracticeSessionManager
10. Manager updates state and triggers appropriate action
11. Loop continues until "stop" or form completes

### 7.2 Form Creation Flow
1. User taps "New Form" in FormsListView
2. App navigates to FormEditorView
3. User enters title and moves (can paste)
4. User taps Save
5. FormStore validates and parses input
6. Form saved to UserDefaults
7. App returns to FormsListView
8. New form appears in list

### 7.3 Form Editing Flow
1. User taps Edit on form in FormsListView
2. App navigates to FormEditorView with existing data
3. User modifies title and/or moves
4. User taps Save
5. FormStore validates and updates form
6. App returns to FormsListView
7. Updated form appears in list

---

## 8. Error Handling

### 8.1 Voice Recognition Errors
| Error | User Experience | Recovery |
|-------|----------------|----------|
| No microphone permission | Alert directing to Settings | App Settings link |
| Recognition service unavailable | Visual prompt to use manual controls | Stop button available |
| Continuous failed recognition | Show "Tap Stop to exit" message | Manual stop button |

### 8.2 Text-to-Speech Errors
| Error | User Experience | Recovery |
|-------|----------------|----------|
| TTS initialization failure | Alert with error message | Return to forms list |
| Speech interruption | Log error, continue session | Next command advances normally |

### 8.3 Data Errors
| Error | User Experience | Recovery |
|-------|----------------|----------|
| Empty form title | Validation error, cannot save | User must enter title |
| Empty moves list | Validation error, cannot save | User must enter at least one move |
| Line exceeds 200 characters | Validation error on save | User must shorten line |
| Load form failure | Alert, return to list | Form excluded from list |

### 8.4 State Errors
| Error | User Experience | Recovery |
|-------|----------------|----------|
| TTS/Recognition conflict | Log error, prioritize TTS | System enforces mutual exclusion |
| Invalid state transition | Log error, ignore command | User can retry command |

---

## 9. User Interface Specifications

### 9.1 FormsListView
**Layout:**
- Navigation title: "Kata Dōshi"
- List of forms (scrollable)
- "+" button in navigation bar (add new form)

**List Item:**
- Form title (bold, 18pt)
- Last practiced date (if available, gray, 14pt)
- Chevron right indicator
- Swipe actions: Delete (red)

**Empty State:**
- "No Forms Yet" message
- "Tap + to create your first form" subtitle

### 9.2 FormEditorView
**Layout:**
- Navigation title: "New Form" or "Edit Form"
- Save button in navigation bar (disabled if invalid)
- Cancel button in navigation bar

**Form Fields:**
- Title field:
  - Placeholder: "Form Name"
  - Required indicator
  - Single line
  
- Moves editor:
  - Placeholder: "Enter moves, one per line"
  - Multi-line
  - Monospace font (for paste alignment)
  - Minimum 3 lines tall, expands as needed

**Delete Button (Edit only):**
- Bottom of screen
- Red, destructive style
- Confirmation alert

### 9.3 PracticeView
**Layout:**
- Full screen, minimal chrome
- White background for readability

**Elements (top to bottom):**
1. Move counter (top, centered, gray, 16pt)
   - "Move 5 of 12"
   
2. Instruction text (center, large, 24pt, bold)
   - Current move instruction
   - Black text
   
3. Status indicator (below instruction, centered)
   - "Say 'start' to begin" (Ready)
   - "Listening..." (Listening, green)
   - "Speaking..." (Speaking, blue)
   - "Paused" (Paused, orange)
   - "Still there? Say 'next' to continue" (Timeout)
   - "Form Complete!" (Completed, green)
   
4. Start/Resume button (when in Ready or Paused state)
   - Centered
   - Blue, prominent
   
5. Stop button (bottom, centered, always visible)
   - Red
   - "Stop" label

**Colors:**
- Background: White
- Text: Black
- Status indicators: As noted above
- Stop button: Red (#FF3B30)
- Start button: Blue (#007AFF)

### 9.4 UI Design System & Conventions

**Note:** These conventions represent initial design decisions for MVP consistency. All choices are subject to refinement based on implementation experience and user feedback.

#### Color System
- **Primary Approach:** Use iOS system colors (`.red`, `.blue`, `.green`, etc.) for semantic consistency
- **Custom Colors:** Only where PRD explicitly specifies hex values (#FF3B30, #007AFF)
- **Semantic State Colors:**
  - Listening: `.green`
  - Speaking: `.blue`
  - Paused: `.orange`
  - Destructive actions: `.red`

#### Typography
- **Dynamic Type:** Use Dynamic Type sizes (`.title`, `.body`, `.caption`, etc.) for accessibility support where appropriate
- **Fixed Sizes:** Use PRD-specified point sizes (16pt, 18pt, 24pt) for practice view where readability from distance is critical
- **Type Hierarchy:**
  - Navigation titles: System default (`.largeTitle` or `.title`)
  - Form titles: 18pt bold (as specified in PRD)
  - Practice instructions: 24pt bold (as specified in PRD)
  - Body text: System `.body` style
  - Secondary text: 14pt or `.caption` style

#### Spacing & Layout
- **Spacing Scale:** Use multiples of 4/8/16/24/32pt for consistent rhythm
- **Safe Areas:** Respect system safe areas for all views
- **Padding:** Standard 16pt horizontal padding for content, 8pt for compact elements

#### Button Styles
- **Primary Actions:** `.borderedProminent` style (e.g., Start/Resume buttons)
- **Secondary Actions:** `.bordered` style
- **Destructive Actions:** `.bordered` with `.destructive` role (outlined red button)
  - Example: Delete button in FormEditorView
- **Navigation Bar Buttons:** Default `.plain` style (system standard)
- **Text-Only Actions:** `.plain` style for tertiary actions

#### List Presentation
- **FormsListView Style:** `.insetGrouped` for modern, polished appearance
- **Row Content:** Follow system standards for list rows (title, subtitle, chevron, swipe actions)
- **Empty States:** Centered message with subtitle guidance

#### Icons & Symbols
- **Icon System:** SF Symbols for all icons (system consistency)
- **Chevrons:** System-provided disclosure indicators
- **Navigation Actions:** SF Symbol icons (e.g., "plus" for add button)

#### State Management Pattern
- **Observability:** Use `@Observable` macro for state objects (iOS 17+)
- **View State:** `@State` for local view state
- **Shared State:** `@Environment` for dependency injection where appropriate

#### Navigation Pattern
- **Navigation Container:** `NavigationStack` with path-based navigation (iOS 16+)
- **Dismissal:** `@Environment(\.dismiss)` for programmatic view dismissal
- **Deep Linking:** Consider navigation path for future deep linking support

#### Error Presentation
- **Validation Errors:** `.alert(error:)` modifier with error binding
- **Permission Errors:** Alert with Settings link
- **Inline Errors:** Below form fields where contextually appropriate

#### Accessibility
- **Dynamic Type:** Support system text sizing throughout
- **VoiceOver:** Semantic labels for all interactive elements
- **Contrast:** Follow system color adaptations for dark mode and high contrast

---

## 10. Non-Functional Requirements

### 10.1 Performance
- Form list must load in < 500ms
- Voice command recognition latency < 1 second
- TTS must begin within 200ms of command
- App launch to ready state < 2 seconds

### 10.2 Reliability
- Voice recognition accuracy target: > 95% in quiet environment
- App must not crash on invalid form data
- Phone calls and system interruptions stop the practice session (user must restart manually)

### 10.3 Usability
- New users should be able to create and practice a form within 2 minutes
- Voice commands should feel natural and conversational
- UI should be readable from 3-6 feet away during practice

### 10.4 Accessibility
- Support for Dynamic Type (text sizing)
- VoiceOver compatibility for all UI elements
- High contrast mode support

### 10.5 Privacy
- No data leaves device
- No analytics or tracking
- Microphone access only during practice sessions

---

## 11. Technical Constraints

### 11.1 iOS Requirements
- **Minimum iOS Version:** iOS 17.0
- **Devices:** iPhone only for MVP (iPad support future)
- **Frameworks Required:**
  - Speech (voice recognition)
  - AVFoundation (text-to-speech)
  - SwiftUI (user interface)
  - Observation (for @Observable macro)

### 11.2 Permissions Required
- Microphone access (for voice commands)
- Speech recognition (for command processing)

### 11.3 Storage
- UserDefaults for form storage (adequate for MVP)
- Estimated max storage: < 1MB for typical use (50 forms)

### 11.4 Dependencies
- **Native iOS frameworks only** (no third-party dependencies)
- Speech framework for voice recognition
- AVFoundation for text-to-speech
- SwiftUI for user interface
- **Rationale:** Minimize complexity, avoid dependency management, ensure long-term maintainability

---

## 12. Success Metrics

### 12.1 MVP Success Criteria
1. **Functionality:** User can create, edit, and practice forms using voice commands
2. **Reliability:** Voice commands work correctly > 95% of the time in quiet environment
3. **Usability:** 3 test users can complete full practice session without assistance
4. **Stability:** Zero crashes during typical use scenarios
5. **Test Coverage:**
   - 80%+ code coverage for business logic (models, stores, services, managers)
   - 100% coverage for PracticeSessionManager state machine transitions
   - Unit tests for FormStore parsing/validation and error handling
   - Integration tests for TTS ↔ Speech recognition coordination
   - UI tests for critical paths (create form, complete practice session)

### 12.2 Future Metrics (Post-MVP)
- Daily active users
- Forms practiced per session
- Average session length
- User retention (7-day, 30-day)
- Feature adoption rates

---

## 13. Development Phases

### 13.1 Phase 1: MVP (Priority: MUST HAVE)
**Duration:** 4-6 weeks

**Deliverables:**
- Form CRUD functionality
- Voice-controlled practice sessions
- Basic UI (list, editor, practice views)
- Core voice commands (start, next, back, repeat, stop, pause)
- UserDefaults persistence

**Success Criteria:** Can practice a complete form end-to-end using voice commands

### 13.2 Phase 2: Enhancements (Priority: SHOULD HAVE)
**Duration:** 2-3 weeks

**Deliverables:**
- Timed auto-advance mode
- Voice/speed customization
- Practice statistics
- Jump to move command
- Form categories

### 13.3 Phase 3: Advanced Features (Priority: NICE TO HAVE)
**Duration:** 4-6 weeks

**Deliverables:**
- Screen-off mode
- Background audio
- Export/import forms
- iPad support
- Checkpoint mode

### 13.4 Phase 4: Android (Priority: CONDITIONAL)
**Duration:** 8-12 weeks

**Condition:** If iOS version proves successful and there's user demand

**Deliverables:**
- Native Android app with feature parity
- Cross-platform form format

---

## 14. Open Questions & Future Considerations

### 14.1 Open Questions
1. Should there be a maximum number of moves per form?
2. Should forms be shareable between users?
3. Should there be preset forms for common martial arts?
4. Should the app support multiple languages for instructions?

### 14.2 Future Considerations
1. Integration with wearables (Apple Watch)
2. Video recording during practice
3. Social features (share forms with students)
4. Instructor mode (remote practice monitoring)
5. Form libraries by martial arts style
6. Integration with belt testing requirements

---

## 15. Dependencies & Risks

### 15.1 Technical Dependencies
- Apple Speech Recognition API availability and reliability
- iOS microphone and speech permissions granted by user
- Device microphone hardware quality

### 15.2 Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Voice recognition accuracy too low | High | Medium | Test extensively in realistic conditions; provide manual fallback |
| Noisy environment interference | Medium | High | Document optimal usage conditions; improve command matching |
| TTS voice quality poor | Low | Low | Allow voice customization in future |
| UserDefaults size limits | Medium | Low | Monitor storage, plan migration to Core Data if needed |
| iOS Speech API changes | High | Low | Stay updated on iOS releases; maintain backward compatibility |

---

## 16. Glossary

| Term | Definition |
|------|------------|
| Form | A sequence of martial arts moves (also called kata, poomsae, taolu) |
| Kata | Japanese term for "form" - a choreographed pattern of movements |
| TTS | Text-to-Speech - technology that converts text to spoken audio |
| MVP | Minimum Viable Product - initial version with core features only |
| Voice Command | Spoken word or phrase that triggers an app action |
| Practice Session | Active use of the app to go through a form with audio guidance |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-01 | Product Team | Initial MVP specification |
| 1.1 | 2025-11-03 | Development Team | Updated iOS requirement to 17.0; Added UI Design System & Conventions (Section 9.4) |

---

## Approval

This document represents the agreed-upon requirements for Kata Dōshi MVP development.

**Next Steps:**
1. Technical design review
2. UI/UX mockups
3. Development sprint planning
4. Test plan creation
