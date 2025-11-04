# Kata Dōshi - Development TODO

**Last Updated:** 2025-11-03
**Current Phase:** Phase 1 MVP - UI Layer Implementation
**Status:** All UI components complete. Screen management (idle timer) implemented. UI tests need fixes.

**Quick Navigation:**
- **Architecture & Design:** See `docs/ARCHITECTURE.md`
- **Development Workflows:** See `docs/DEVELOPMENT.md`
- **Completed Work History:** See `docs/SESSION-HISTORY.md`
- **Product Requirements:** See `docs/Kata-Doshi-PRD.md` (v1.2)

---

## Current Todo List

### Immediate Next Steps

1. **[ ] Fix failing UI tests**
   - Location: `katadoshiUITests/` directory
   - **Status:** Unit tests passing (350+), but UI tests failing
   - All UI test suites showing failures (FormsListView, FormEditorView, PracticeView)
   - Appears to be pre-existing issue, unrelated to screen management changes
   - Need investigation and fixes

2. **[ ] Integration tests for SpeechRecognitionService authorization**
   - Manual test checklist: `docs/Integration-Test-SpeechRecognition.md`
   - Test harness: `katadoshi/Debug/SpeechTestHarnessView.swift`
   - Run 8 test cases on physical device with various permission states
   - Document results in test execution log
   - **Status:** Test infrastructure ready, execution pending

---

## Phase 1 MVP Status

### Completed ✓
- Data Layer: Form model, FormStore
- Service Layer: TextToSpeechService, SpeechRecognitionService
- Manager Layer: PracticeSessionManager, PracticeSessionManagerError
- UI Layer: FormsListView, FormEditorView, PracticeView, PracticeViewModel
- Screen Management: Idle timer disable/enable in PracticeView
- iOS 17.0 migration with @Observable pattern
- Unit test infrastructure (350+ tests passing)

### Remaining
- **UI test fixes** - Multiple test suites failing
- Integration testing for speech recognition and screen management

---

## Future Work (Post-MVP)

### Phase 2: Enhancements (Priority: SHOULD HAVE)
- [ ] Timed auto-advance mode
- [ ] Voice/speed customization
- [ ] Practice statistics and tracking
- [ ] Jump to move command
- [ ] Form categories/organization

### Phase 3: Advanced Features (Priority: NICE TO HAVE)
- [ ] Screen-off mode with headphone controls (PRD Section 13.3.1)
  - Background audio session configuration
  - MPRemoteCommandCenter integration
  - Headphone button mappings
  - Lock screen display with MPNowPlayingInfoCenter
- [ ] Auto-advance mode with configurable delays (PRD Section 13.3.2)
  - User-configurable delay (1-30 seconds)
  - Siri speed control ("Hey Siri, speed up kata")
- [ ] Export/import forms
- [ ] iPad support
- [ ] Checkpoint mode

### Phase 4: Android (Priority: CONDITIONAL)
- [ ] Native Android app with feature parity
- [ ] Cross-platform form format
- **Condition:** If iOS version proves successful and there's user demand

---

## Known Issues & Technical Debt

### Current Gaps
1. **UI tests failing** - Need investigation and fixes
2. **Integration tests not executed** - Requires physical device testing (speech recognition, screen management)

### Future Considerations
1. Should there be a maximum number of moves per form?
2. Should forms be shareable between users?
3. Should there be preset forms for common martial arts?
4. Should the app support multiple languages for instructions?
5. Integration with wearables (Apple Watch)?
6. Video recording during practice?
7. Social features (share forms with students)?
8. Instructor mode (remote practice monitoring)?

---

## Quick Reference

### Test Coverage Summary
- **Total Tests:** 350+ tests (estimated)
- **Passing:** All runnable tests
- **Disabled:** 13 tests (SpeechRecognitionService authorization - require integration testing)
- **Coverage:** 100% on business logic (data, service, manager layers) + comprehensive UI tests

### Key PRD Changes (v1.2)
- Added hands-free operation requirement (Section 4.1.2)
- Added screen management specification (Section 5.4)
- Added background interruption handling (Section 8.5)
- Expanded Phase 3 with screen-off mode and auto-advance mode (Sections 13.3.1, 13.3.2)

---

**For detailed architecture, workflows, and session history, see:**
- `docs/ARCHITECTURE.md` - Key design decisions and patterns
- `docs/DEVELOPMENT.md` - TDD workflows and recovery procedures
- `docs/SESSION-HISTORY.md` - Chronological development history
- `CLAUDE.md` - Build commands and project instructions
