# Kata Dōshi - Integration Test Workflow

**Purpose:** Complete pre-release validation workflow combining speech recognition authorization tests and manual QA. Must be executed on physical device before release.

**Time Estimate:** 30-45 minutes

**Test Date:** _______________
**iOS Version:** _______________
**Device Model:** _______________
**Build Version:** _______________
**Tester:** _______________

---

## Prerequisites

### Device Requirements
- **Physical iOS device** (speech recognition and idle timer tests don't work reliably in simulator)
- iOS 16.0 or later
- Ability to modify Settings → Privacy & Security → Microphone
- Clean install capability OR reset permissions via Settings → General → Transfer or Reset iPhone → Reset Location & Privacy

### Testing Environment
- Quiet environment for voice recognition tests
- Device unlocked and awake
- Recommended: Test on both small screen (iPhone SE) and large screen (iPhone 15 Pro Max) if available

---

## Part 1: Speech Recognition Authorization Tests

**Time:** ~15 minutes
**Objective:** Verify microphone permission handling meets PRD Section 8.1 requirements

### Setup: Reset Permissions

Before starting, ensure fresh permission state:
- Settings → General → Transfer or Reset iPhone → Reset Location & Privacy
- OR perform fresh app install

---

### TC-SR-AUTH-01: First Launch Permission Request

**Objective:** Verify permission alert appears when microphone access is not yet determined

**Test Steps:**
1. Launch Kata Dōshi app (first time after permission reset)
2. Tap "+" to create a test form:
   - Title: "Permission Test"
   - Moves: "Move 1" / "Move 2" / "Move 3"
3. Save form and tap it to enter Practice View
4. Tap "Start" button

**Expected Results:**
- [ ] iOS system permission alert appears
- [ ] Alert title: "Kata Dōshi Would Like to Access the Microphone"
- [ ] Two buttons: "Don't Allow" and "OK"
- [ ] Practice mode waits for user response

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-02: Permission Granted Flow

**Objective:** Verify service starts correctly when user grants permission

**Test Steps:**
1. On permission alert (from TC-SR-AUTH-01), tap "OK"
2. Observe practice view behavior

**Expected Results:**
- [ ] Alert dismisses immediately
- [ ] Practice view shows "Listening..." indicator
- [ ] Service begins recognizing voice commands (test: say "next")
- [ ] Move advances when "next" is spoken
- [ ] No error alerts appear

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-03: Permission Denied Behavior

**Objective:** Verify correct handling when user denies microphone permission

**Test Steps:**
1. Exit practice view (tap back button)
2. Go to Settings → Privacy & Security → Microphone → Kata Dōshi = OFF
3. Return to app, start practice session again

**Expected Results:**
- [ ] NO system permission alert (permission already determined)
- [ ] App displays error alert:
  - Title: "Microphone Access Required" or similar
  - Message explains need for microphone
  - "Open Settings" button present
  - "Cancel" button present
- [ ] Practice mode does NOT start
- [ ] No speech recognition active

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-04: Open Settings Deep Link

**Objective:** Verify "Open Settings" button navigates correctly

**Test Steps:**
1. On error alert (from TC-SR-AUTH-03), tap "Open Settings"

**Expected Results:**
- [ ] Settings app opens
- [ ] Navigates directly to Settings → Kata Dōshi
- [ ] Microphone toggle visible and currently OFF

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-05: Permission Re-granted

**Objective:** Verify service works after user grants permission following denial

**Test Steps:**
1. In Settings → Kata Dōshi, toggle Microphone permission ON
2. Return to Kata Dōshi app (App Switcher, don't force quit)
3. Start practice session

**Expected Results:**
- [ ] NO permission alert (already authorized)
- [ ] Practice starts immediately
- [ ] Service recognizes voice commands
- [ ] No error messages

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-06: Permission Restricted (Optional)

**Objective:** Verify handling when microphone is restricted by Screen Time

**Prerequisites:** Enable Screen Time → Content & Privacy Restrictions → Microphone = "Don't Allow"

**Test Steps:**
1. Launch app, start practice session

**Expected Results:**
- [ ] Similar behavior to TC-SR-AUTH-03 (denied state)
- [ ] Error alert shown
- [ ] Practice does NOT start

**Result:** ☐ Pass  ☐ Fail  ☐ Skipped (requires Screen Time setup)
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-07: Background/Foreground Transition

**Objective:** Verify service handles permission changes while app backgrounded

**Test Steps:**
1. Ensure microphone permission ON
2. Start practice session (service listening)
3. Background app (Home button/gesture)
4. Settings → Privacy → Microphone → Kata Dōshi = OFF
5. Return to app via App Switcher

**Expected Results:**
- [ ] Service detects permission change (may require app relaunch)
- [ ] Practice session stops gracefully OR error shown on foreground
- [ ] User prompted to re-enable permission

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### TC-SR-AUTH-08: Recognizer Unavailable (Edge Case)

**Objective:** Verify handling when speech recognizer unavailable (not permission-related)

**Test Steps:**
1. With microphone permission granted, observe if recognizer initialization ever fails

**Expected Results:**
- [ ] If recognizer unavailable, error message distinguishes from permission issues
- [ ] Manual stop button remains available
- [ ] Different error message than permission denial

**Result:** ☐ Pass  ☐ Fail  ☐ Cannot Test (recognizer always available)
**Notes:** _______________________________________________________

---

## Part 2: Full Manual QA Checklist

**Time:** ~20-30 minutes
**Objective:** Validate all critical functionality before release

---

### 1. App Launch & Empty State (30 seconds)

**Test Steps:**
1. Delete app and reinstall fresh OR clear all forms
2. Launch app

**Checklist:**
- [ ] App launches without crashing
- [ ] Navigation bar displays "Kata Dōshi" title
- [ ] Empty state: "No Forms Yet" message
- [ ] Empty state: "Tap + to create your first form" subtitle
- [ ] "+" button visible in toolbar

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 2. Form Creation (45 seconds)

**Test Steps:**
1. Tap "+" button
2. Enter title: "Test Form"
3. Enter moves (one per line):
   ```
   Front stance
   Down block
   Step forward
   Middle punch
   ```
4. Tap "Save"

**Checklist:**
- [ ] Form editor appears as modal sheet (slides up from bottom)
- [ ] Save button disabled when both fields empty
- [ ] Save button disabled when only title filled
- [ ] Save button enabled when both fields have content
- [ ] Save button style: blue/prominent when enabled, gray when disabled
- [ ] Tapping "Save" returns to list
- [ ] Form appears in list with title "Test Form"
- [ ] Form shows "Created [time] ago" under title

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 3. Form Deletion (45 seconds)

**Test Steps:**
1. Swipe left on "Test Form"
2. Tap "Delete"
3. Tap "Cancel" on confirmation alert
4. Swipe left again, tap "Delete"
5. Tap "Delete" to confirm

**Checklist:**
- [ ] Swipe reveals Delete and Edit buttons
- [ ] Confirmation alert appears with title "Delete this form?"
- [ ] Alert has "Cancel" (default) and "Delete" (red/destructive) buttons
- [ ] "Cancel" dismisses alert, form remains
- [ ] "Delete" removes form immediately
- [ ] Empty state reappears after last form deleted

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 4. Practice Session - Basic Flow (60 seconds)

**Test Steps:**
1. Create form with 3 moves
2. Tap form to enter Practice View
3. Tap "Start" button
4. After first move spoken and "Listening..." appears, tap "Next"
5. After second move spoken, tap "Stop"

**Checklist:**
- [ ] Navigation bar shows form title (not "Kata Dōshi")
- [ ] Initial view shows:
  - [ ] Move counter "1 of 3"
  - [ ] Current move text
  - [ ] "Say 'start' or tap Start button" prompt
  - [ ] Start button (blue/prominent)
  - [ ] Stop button (red, bottom)
- [ ] After tapping "Start":
  - [ ] "Speaking..." indicator appears
  - [ ] Move 1 spoken aloud by TTS
  - [ ] After speech: "Listening..." indicator appears
  - [ ] Move counter still "1 of 3"
- [ ] After tapping "Next":
  - [ ] Move counter updates to "2 of 3"
  - [ ] "Speaking..." appears
  - [ ] Move 2 spoken aloud
- [ ] Tapping "Stop" returns to forms list

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 5. Navigation & Back Buttons (60 seconds)

**Checklist:**
- [ ] Forms list → Tap form → Practice View opens
- [ ] Practice View → Tap back → Returns to forms list (no crash)
- [ ] Forms list → Tap "+" → Editor opens as modal sheet (not push)
- [ ] Editor → Tap "Cancel" → Returns to list (no form saved)
- [ ] Forms list → Swipe left → "Edit" button appears
- [ ] Tap "Edit" → Editor opens as modal sheet
- [ ] Editor → Tap "Cancel" → Returns to list (changes not saved)

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 6. Form Editing

**Test Steps:**
1. Create form "Original Title" with 2 moves
2. Swipe left, tap "Edit"
3. Change title to "Edited Title"
4. Add third move
5. Tap "Save"

**Checklist:**
- [ ] Editor opens with title pre-populated "Original Title"
- [ ] Moves field pre-populated with 2 moves
- [ ] Save button enabled initially (fields have content)
- [ ] After editing, title changed to "Edited Title" in list
- [ ] Opening practice shows 3 moves present

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 7. Multiple Forms

**Test Steps:**
1. Create 5 different forms with distinct titles
2. Delete one form from middle of list

**Checklist:**
- [ ] All 5 forms appear in list
- [ ] Forms displayed in consistent order
- [ ] Each form shows "Created [time]" label
- [ ] After deleting one, others remain in same order
- [ ] List scrollable if needed

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 8. Edge Cases

#### Long Form Title
**Test:** Create form with title "This is a very long form title that should test proper display and truncation behavior in the list view"

**Checklist:**
- [ ] Title displays in list (truncated with ... if needed)
- [ ] Full title visible in editor and practice view

#### Special Characters
**Test:** Create form "形同士 Special Characters & Symbols!"

**Checklist:**
- [ ] Title displays correctly in all views
- [ ] No crashes or encoding issues

#### Move Length
**Test:** Create form with move >200 characters

**Checklist:**
- [ ] App rejects or handles gracefully (per PRD: reject >200 char lines)

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 9. Practice Session - Advanced

#### Voice Commands (Physical Device Required)
**Test Steps:**
1. Create form with 3 moves, start practice
2. Say "next" after first move → Advances to move 2
3. Say "back" → Returns to move 1
4. Say "repeat" → Repeats move 1
5. Say "pause" → Session pauses
6. Say "start" → Resumes from same move
7. Complete all moves → Completion message

**Checklist:**
- [ ] "next" advances move, counter increments
- [ ] "back" goes to previous, counter decrements
- [ ] "repeat" repeats current, counter unchanged
- [ ] "pause" pauses session
- [ ] "start" resumes from correct move
- [ ] Completion message shows after last move
- [ ] Stop button works at any point

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 10. Screen Management (Idle Timer) - CRITICAL

**IMPORTANT:** MUST test on physical device (idle timer doesn't work in simulator)

**Prerequisites:** Set device auto-lock to 30 seconds (Settings → Display & Brightness → Auto-Lock → 30 Seconds)

**Test Steps:**
1. Start practice session
2. Wait 5+ minutes without interacting
3. Say "pause"
4. Wait 2+ minutes
5. Say "start" to resume
6. Complete form to "Form Complete!" state
7. Wait 2+ minutes (observe screen behavior)
8. Say "start" from completed state
9. Tap "Stop" mid-session
10. Exit practice view

**Checklist:**
- [ ] **Session Start:** Screen does NOT auto-lock during active practice (5+ min test)
- [ ] **Mid-Session:** Screen stays on through multiple moves
- [ ] **Pause State:** Screen does NOT auto-lock while paused
- [ ] **Resume from Pause:** Screen continues to stay on
- [ ] **Complete Session:** Screen DOES auto-lock after form completes (30 sec with above setting)
- [ ] **Restart from Completed:** Screen does NOT auto-lock again during practice
- [ ] **Stop Early:** Tapping "Stop" restores normal auto-lock behavior
- [ ] **Navigate Away:** Swiping back to forms list restores normal auto-lock
- [ ] **Manual Lock:** Locking phone mid-practice pauses session, unlock + resume works

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 11. Accessibility (VoiceOver) - REQUIRED

**Prerequisites:** Enable VoiceOver (Settings → Accessibility → VoiceOver)

**Checklist:**
- [ ] Navigate forms list with swipe gestures
- [ ] Form rows read title and date clearly
- [ ] "+" button labeled ("Add Form" or similar)
- [ ] Can complete form creation using only VoiceOver:
  - [ ] Activate "+" button
  - [ ] Enter title and moves
  - [ ] Activate "Save" button
- [ ] Can start practice session using VoiceOver:
  - [ ] Navigate to form, activate
  - [ ] Activate "Start" button
  - [ ] Activate "Stop" button
- [ ] All interactive elements reachable

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

### 12. Performance & Stability

**Checklist:**
- [ ] App launches in <2 seconds
- [ ] Form list loads instantly (<500ms)
- [ ] Practice session TTS begins <200ms after "Start"
- [ ] Voice commands recognized in <1 second
- [ ] No crashes during entire test session
- [ ] No memory warnings
- [ ] Smooth animations throughout

**Result:** ☐ Pass  ☐ Fail
**Notes:** _______________________________________________________

---

## Part 3: Final Sign-Off

### Overall Test Results

**Speech Recognition Authorization Tests:**
- TC-SR-AUTH-01: ☐ Pass  ☐ Fail
- TC-SR-AUTH-02: ☐ Pass  ☐ Fail
- TC-SR-AUTH-03: ☐ Pass  ☐ Fail
- TC-SR-AUTH-04: ☐ Pass  ☐ Fail
- TC-SR-AUTH-05: ☐ Pass  ☐ Fail
- TC-SR-AUTH-06: ☐ Pass  ☐ Fail  ☐ Skipped
- TC-SR-AUTH-07: ☐ Pass  ☐ Fail
- TC-SR-AUTH-08: ☐ Pass  ☐ Fail  ☐ Cannot Test

**Manual QA Checklist:**
- App Launch & Empty State: ☐ Pass  ☐ Fail
- Form Creation: ☐ Pass  ☐ Fail
- Form Deletion: ☐ Pass  ☐ Fail
- Practice Session Basic: ☐ Pass  ☐ Fail
- Navigation & Back Buttons: ☐ Pass  ☐ Fail
- Form Editing: ☐ Pass  ☐ Fail
- Multiple Forms: ☐ Pass  ☐ Fail
- Edge Cases: ☐ Pass  ☐ Fail
- Practice Session Advanced: ☐ Pass  ☐ Fail
- Screen Management (Idle Timer): ☐ Pass  ☐ Fail
- Accessibility (VoiceOver): ☐ Pass  ☐ Fail
- Performance & Stability: ☐ Pass  ☐ Fail

---

### Release Decision

**Overall Result:** ☐ PASS - Ready for Release  ☐ FAIL - Blocking Issues Found

**Blocking Issues (must fix before release):**
```
[List any critical bugs that block release]
```

**Non-Blocking Issues (can defer to next release):**
```
[List minor issues that don't block release]
```

**Additional Notes:**
```
[Any other observations, performance notes, or recommendations]
```

---

### Sign-Off

**Tester Name:** ______________________________
**Signature:** ______________________________
**Date:** ______________________________

**Approved for Release:** ☐ Yes  ☐ No (see blocking issues above)

---

## Quick Reference: Test Data

**Basic Test Form:**
```
Title: "Test Form"
Moves:
- Front stance
- Down block
- Step forward
- Middle punch
```

**Minimal Form:**
```
Title: "One Move"
Moves:
- Single move
```

**Edge Case Form:**
```
Title: "形同士 Special Characters & Symbols!"
Moves:
- Move with 特殊 characters
- Very long move: [200+ character string to test rejection]
```

---

## Related Documentation

- **PRD:** `docs/Kata-Doshi-PRD.md` (v1.2)
- **Architecture:** `docs/ARCHITECTURE.md`
- **Development Workflows:** `docs/DEVELOPMENT.md`
- **Session History:** `docs/SESSION-HISTORY.md`
- **TODO:** `docs/TODO.md`

---

**Document Version:** 1.0
**Last Updated:** 2025-11-04
**Author:** Claude Code
