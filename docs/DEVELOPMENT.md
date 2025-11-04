# Kata Dōshi - Development Workflows

**Last Updated:** 2025-11-03

This document describes the development workflows, recovery procedures, and conventions for the Kata Dōshi project.

---

## Session Recovery Checklist

If starting a new session:

1. **[ ] Read PRD** (`docs/Kata-Doshi-PRD.md`) - Understand product requirements (now v1.2)
2. **[ ] Read TODO** (`docs/TODO.md`) - Current actionable tasks
3. **[ ] Read ARCHITECTURE** (`docs/ARCHITECTURE.md`) - Key design decisions
4. **[ ] Read CLAUDE.md** - Build commands, architecture, TDD workflow
5. **[ ] Run all tests** - Verify current state (should be 350+ passing, 13 disabled)
6. **[ ] Check next todo item** - Screen management (idle timer) is the remaining MVP requirement

**Current State Verification:**
```bash
# Should show 350+ passing tests
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Current Status:**
- All Phase 1 MVP components implemented EXCEPT screen management
- PracticeView, PracticeViewModel, and all UI layer complete
- Screen management (idle timer) is the only remaining MVP requirement

---

## Test Driven Development Workflow

This project follows a strict TDD approach with agent-assisted feature development cycles:

### Feature Development Cycle

1. **Technical Planning (Groucho)**
   - Groucho reviews the next feature to be implemented
   - Proposes a technical plan based on existing patterns and PRD requirements
   - Ensures alignment with project architecture

2. **Test Design (Zeppo)**
   - Zeppo writes unit tests for the feature based on the technical plan
   - Tests should cover requirements from the PRD
   - **Parallel execution:** For multi-file features, Zeppo can analyze the test structure and launch multiple duck agents in parallel (nicknamed Huey, Dewey, and Louie) to write different test files simultaneously

3. **Test Review (Chico)**
   - Chico critiques the tests for completeness and correctness
   - Identifies gaps, edge cases, or deviations from PRD

4. **Test Iteration (Zeppo ↔ Chico)**
   - Zeppo revises tests based on Chico's feedback
   - Chico reviews updated tests
   - **Repeat until both agents agree tests are appropriate for the feature**
   - **Parallel execution:** Zeppo can delegate revisions to duck agents when changes span multiple files

5. **Implementation**
   - Work on code until all tests pass
   - Follow the technical plan from step 1
   - **Parallel execution:** For features spanning multiple modules, the main agent can analyze dependencies and launch multiple duck agents in parallel to implement different files/modules simultaneously

6. **Code Review (Chico)**
   - Chico reviews implementation for:
     - Correctness
     - Adherence to PRD requirements
     - Code quality

7. **Issue Resolution**
   - Fix **critical** and **important** issues identified by Chico
   - Minor issues can be neglected
   - Chico must review changes after fixes
   - **Iterate on bug fixes, test validation, and Chico's review until both agree the feature is complete**
   - **Parallel execution:** Main agent can use duck agents for parallel bug fixes across multiple files

8. **Final Approval and Completion**
   - **Chico must provide final approval** confirming the implementation is complete and correct
   - **Wait for human confirmation** before proceeding to finalization
   - Once human confirms:
     1. Update TODO.md to mark the feature as complete
     2. Commit changes to git with descriptive commit message
   - **IMPORTANT:** Do not declare a feature complete, update TODO.md, or commit to git until both Chico's final approval AND human confirmation are received

### Parallel Execution with Duck Agents

The **duck agent** is a Haiku-powered generic code/test writer that enables parallel task execution:

- **What it is:** A fast, cost-effective worker agent that can be invoked multiple times in parallel
- **Names:** Parallel invocations are nicknamed "Huey, Dewey, and Louie" for flavor (like the Marx Brothers convention)
- **When to use:** Multi-file features, independent modules, or when test/code changes can be parallelized
- **When to skip:** Single-file changes, tightly coupled logic, or when coordination overhead exceeds benefits
- **Orchestration:** Zeppo (during test writing) or main agent (during implementation) analyzes the work, determines how to split it, and assigns specific files/modules to each duck agent

---

## Build Commands

**Build:**
```bash
xcodebuild -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 15' build
```

**Run all tests:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Run unit tests only:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:katadoshiTests
```

**Run UI tests only:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:katadoshiUITests
```

**Run specific test suite:**
```bash
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:katadoshiTests/SpeechRecognitionServiceTests
```

**Clean:**
```bash
xcodebuild clean -project katadoshi.xcodeproj -scheme katadoshi
```

---

## Git Commit Message Format

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

### Example:

```
Implement Phase 1 MVP: Data and service layers with comprehensive tests

Data Layer:
- Form model with Codable, Identifiable, Equatable (42 tests)
- FormStore with UserDefaults persistence, CRUD operations, validation, and move parsing (85 tests)
- FormStoreError enum with custom descriptions

Service Layer:
- TextToSpeechService with AVSpeechSynthesizer integration (69 tests)
- Protocol-based design for testability and dependency injection
- Completion callbacks for state machine coordination

Configuration:
- Set iOS deployment target to 16.0 per PRD requirements
- Added comprehensive PRD documentation

Test Coverage:
- 196 total tests passing (100% coverage on business logic)
- Uses Swift Testing framework with @MainActor isolation
- TDD workflow: Groucho (plan) → Zeppo (tests) → Chico (review) → Implementation

All tests passing. Ready for Phase 1 UI components.
```

---

## Notes for Future Sessions

### Questions to Consider

1. **Screen Management Implementation**
   - Should idle timer be managed in PracticeView or PracticeViewModel?
   - How to test idle timer behavior (requires physical device)?
   - Should we add integration test checklist for screen management?

2. **UI Testing Strategy**
   - How to improve UI test coverage for error states?
   - Should we add snapshot testing for UI consistency?
   - How to test accessibility features (VoiceOver)?

3. **Phase 2 Planning**
   - When to implement timed mode (PRD Phase 2)?
   - Statistics tracking architecture?
   - Export/import format for forms?

4. **Phase 3 Planning**
   - Screen-off mode with headphone controls (PRD Section 13.3.1)
   - Auto-advance mode implementation (PRD Section 13.3.2)
   - MPRemoteCommandCenter integration approach
   - Background audio session configuration

---

## Context from Recent Sessions

### Protocol Abstraction Pattern Established
- Proved successful for testing Apple frameworks with failable initializers
- Pattern can be reused for other Apple framework integrations
- Groucho validated this approach as consistent with project patterns

### Integration Testing Strategy
- Manual testing for system-level behavior (permissions)
- Unit testing for business logic (parsing, state management)
- Test harness for developer verification
- Clear separation of concerns

### TDD Workflow Validated
- Zeppo/Chico iteration caught architectural mismatch early
- Tests serve as executable specifications
- Protocol-based design emerged from testability requirements

### Code Organization
- Tests split into focused files (500-1000 lines each)
- Keeps context windows manageable for AI-assisted development
- Each test file focuses on single component

---

**End of Development Document**
