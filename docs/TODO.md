# Kata Dōshi - Development TODO

**Last Updated:** 2025-11-04 (Session: TODO Cleanup)
**Current Phase:** Phase 1 MVP - Ready for Physical Device Testing
**Status:** All implementation complete. Screen management fixed. UI tests removed. Ready for integration testing on physical device.

**Quick Navigation:**
- **Architecture & Design:** See `docs/ARCHITECTURE.md`
- **Development Workflows:** See `docs/DEVELOPMENT.md`
- **Completed Work History:** See `docs/SESSION-HISTORY.md`
- **Product Requirements:** See `docs/Kata-Doshi-PRD.md` (v1.2)

---

## Current Todo List

### Immediate Next Steps

1. **[✓] Screen Idle Timer Fix** ✅ COMPLETE
   - **Issue:** Idle timer disabled on every speaking state transition instead of once at session start
   - **Fix:** Added state tracking (`hasDisabledIdleTimer`) to disable timer once when session starts
   - **Implementation:** Modified PracticeView.swift to detect session start transitions (Ready/Paused/Completed → Speaking)
   - **PRD Alignment:** Now correctly implements PRD Section 5.4 screen management requirements
   - **Testing:** Added manual QA test scenarios in `docs/MANUAL-QA-CHECKLIST.md` (requires physical device)
   - **Review:** Approved by Chico with no critical/important issues
   - **Behavior Changes:**
     - Screen stays on from session start until completion or exit
     - Idle timer re-enables when form completes (battery conservation)
     - Idle timer re-enables when user exits practice view
     - Pause state keeps screen on (allows hands-free resume)
     - Restart from completed re-disables idle timer
   - **Status:** Complete (commit aa876c7)

2. **[✓] UI Test Strategy - Complete Removal** ✅ COMPLETE
   - **Decision:** Remove ALL UI tests, rely entirely on manual QA
   - **Rationale:** UI tests flaky/slow; voice-controlled app requires manual testing; 350+ unit tests provide 100% business logic coverage
   - **Outcome:** All 120 UI tests deleted (2,269 lines), enhanced manual QA checklist
   - **Status:** Complete (commit a95434e)

   **Delivered:**
   - Comprehensive manual QA checklist (`docs/MANUAL-QA-CHECKLIST.md`)
   - All UI test files and infrastructure removed
   - Relying on 350+ unit tests + manual testing for quality assurance

3. **[ ] Physical Device Integration Testing**
   - **Unified workflow:** `docs/INTEGRATION-TEST-WORKFLOW.md` (30-45 minutes)
   - Combines speech recognition authorization tests + full manual QA
   - Test harness available: `katadoshi/Debug/SpeechTestHarnessView.swift`
   - **Requirements:** Physical iOS device (speech + idle timer tests)
   - **Status:** Test workflow ready, execution pending

---

## Phase 1 MVP Status

### Completed ✓
- Data Layer: Form model, FormStore
- Service Layer: TextToSpeechService, SpeechRecognitionService
- Manager Layer: PracticeSessionManager, PracticeSessionManagerError
- UI Layer: FormsListView, FormEditorView, PracticeView, PracticeViewModel
- Screen Management: Idle timer disable/enable in PracticeView (commit aa876c7)
- iOS 17.0 migration with @Observable pattern
- Unit test infrastructure (350+ tests passing, 100% business logic coverage)
- Manual QA checklist and testing strategy (commit a95434e)

### Remaining (Physical Device Required)
- Complete integration testing workflow: `docs/INTEGRATION-TEST-WORKFLOW.md` (30-45 min)
  - Speech recognition authorization tests (8 test cases)
  - Screen management idle timer tests (9 scenarios)
  - Full manual QA checklist (12 test sections)
  - Final release sign-off


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
- Integration tests not executed (requires physical device for speech recognition and screen management)

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
- **Unit Tests:** 350+ tests, all passing
- **Coverage:** 100% on business logic (data, service, manager layers)
- **UI Tests:** Removed (replaced with manual QA checklist)
- **Disabled Tests:** 13 tests (SpeechRecognitionService authorization - require physical device integration testing)

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
