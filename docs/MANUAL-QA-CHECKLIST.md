# Kata Dōshi - Manual QA Checklist

**Purpose:** Manual testing checklist for pre-release validation. Run this checklist before each release to verify critical functionality.

**Time Estimate:** 5-10 minutes

**Prerequisites:**
- Clean install or cleared app data
- iOS device or simulator (iOS 17.0+)
- Test on both iPhone SE (small screen) and iPhone 15 Pro Max (large screen) if possible

---

## Critical Path Tests (Required)

### 1. App Launch & Empty State (30 seconds)
- [ ] App launches without crashing
- [ ] Navigation bar displays "Kata Dōshi" title prominently
- [ ] Empty state displays "No Forms Yet" message
- [ ] Empty state displays "Tap + to create your first form" subtitle
- [ ] "+" button visible in toolbar
- [ ] Forms list rows show chevron indicator (test after creating a form)

**Expected:** Clean launch, empty state UI appears correctly

---

### 2. Form Creation (45 seconds)
- [ ] Tap "+" button → Form editor appears as modal sheet
- [ ] Verify Save button disabled when editor first opens (grayed out, both fields empty)
- [ ] Enter form title: "Test Form"
- [ ] Verify Save button still disabled (moves field empty)
- [ ] Enter moves (one per line):
  ```
  Front stance
  Down block
  Step forward
  Middle punch
  ```
- [ ] Verify Save button now enabled (blue/prominent style, both fields have content)
- [ ] Tap "Save" → Returns to list
- [ ] Form appears in list with title "Test Form"
- [ ] Form shows "Created [time] ago" under title

**Expected:** Form created successfully and appears in list

---

### 3. Form Deletion (45 seconds)
- [ ] Swipe left on "Test Form"
- [ ] Delete and Edit buttons appear
- [ ] Tap "Delete"
- [ ] Confirmation alert appears with title "Delete this form?"
- [ ] Alert has two buttons: "Cancel" (left/default) and "Delete" (right/destructive red)
- [ ] Tap "Cancel" → Alert dismisses, form still in list
- [ ] Swipe left again, tap "Delete" → Alert appears again
- [ ] Tap "Delete" to confirm
- [ ] Form immediately disappears from list
- [ ] Empty state reappears

**Expected:** Form deleted with confirmation, empty state restored

---

### 4. Practice Session - Basic Flow (60 seconds)
- [ ] Create a new form with 3 moves
- [ ] Tap form to navigate to Practice View
- [ ] Verify navigation bar shows form title (not "Kata Dōshi")
- [ ] Practice View shows:
  - Move counter "1 of 3"
  - Current move text
  - "Say 'start' or tap Start button"
  - Start button
  - Stop button
- [ ] Tap "Start" button
- [ ] "Speaking..." indicator appears
- [ ] Move 1 is spoken aloud
- [ ] After speech completes: "Listening..." indicator appears
- [ ] "Say 'next' or tap Next button" prompt appears
- [ ] Move counter still shows "1 of 3"
- [ ] Tap "Next" button
- [ ] Move counter updates to "2 of 3"
- [ ] "Speaking..." indicator appears again
- [ ] Move 2 is spoken aloud
- [ ] Tap "Stop" button → Returns to forms list

**Expected:** Practice session starts, TTS speaks moves, state indicators display correctly, move counter updates

---

### 5. Navigation & Back Buttons (60 seconds)
- [ ] From forms list, tap a form → Practice View opens
- [ ] Tap back button → Returns to forms list (no crash or hang)
- [ ] From forms list, tap "+" → Form editor opens as modal sheet (not push navigation)
- [ ] Verify editor appears from bottom of screen (sheet presentation)
- [ ] Tap "Cancel" → Sheet dismisses, returns to forms list (no form saved)
- [ ] Swipe left on a form
- [ ] Verify Edit button appears alongside Delete button
- [ ] Tap "Edit" → Form editor opens as modal sheet
- [ ] Tap "Cancel" → Returns to forms list (changes not saved)

**Expected:** All navigation works, Cancel works from both create and edit modes, no hangs or crashes

---

## Secondary Tests (Nice to Have)

### 6. Form Editing
- [ ] Create form "Original Title" with 2 moves
- [ ] Swipe left on form row
- [ ] Verify Edit button appears alongside Delete button
- [ ] Tap "Edit" → Form editor opens as modal sheet
- [ ] Form editor opens with title pre-populated to "Original Title"
- [ ] Moves field pre-populated with existing 2 moves
- [ ] Save button initially enabled (fields have content)
- [ ] Change title to "Edited Title"
- [ ] Add a third move
- [ ] Tap "Save"
- [ ] Verify title changed to "Edited Title" in list
- [ ] Open practice → Verify 3 moves present

**Expected:** Fields pre-populated correctly, edits persist correctly

---

### 7. Multiple Forms
- [ ] Create 5 different forms with distinct titles
- [ ] All 5 appear in list
- [ ] Forms displayed in chronological order (consistent ordering)
- [ ] Each form shows correct "Created [time]" label
- [ ] Delete one from middle → Others remain in same order
- [ ] List remains scrollable if needed

**Expected:** Multiple forms managed correctly, consistent display order

---

### 8. Edge Cases

#### Long Form Title
- [ ] Create form with title: "This is a very long form title that should test proper display and truncation behavior in the list view"
- [ ] Title displays properly in list (truncated with ...)
- [ ] Full title visible in editor and practice view

#### Special Characters
- [ ] Create form with title: "Form with 特殊 characters & symbols!"
- [ ] Title displays correctly in all views
- [ ] No crashes or encoding issues

#### Empty Moves
- [ ] Try to create form with empty moves field → Error or validation?
- [ ] Try to save form with only whitespace → Error or validation?

#### Move Length
- [ ] Create form with very long move (>200 characters)
- [ ] Should reject or handle gracefully

**Expected:** App handles edge cases gracefully, no crashes

---

### 9. Practice Session - Advanced

#### Full Session Flow
- [ ] Create form with 3 moves
- [ ] Start practice
- [ ] Say "next" or tap Next after each move spoken
- [ ] Complete all 3 moves
- [ ] Should show completion message
- [ ] Stop button works at any point

#### Pause/Resume
- [ ] Start practice session
- [ ] Say "pause" or tap Pause
- [ ] Session pauses
- [ ] Say "start" or tap Start to resume
- [ ] Continues from correct move

#### Navigation During Practice
- [ ] Start practice
- [ ] Say "next" to advance → Move counter increments
- [ ] Say "back" to go to previous move → Move counter decrements
- [ ] Say "repeat" to repeat current move → Move counter stays same
- [ ] Move counter accurately reflects current position throughout session

**Expected:** Full voice control works, state machine behaves correctly, move counter always accurate

---

### 10. Accessibility (VoiceOver)

**Note:** REQUIRED for all releases - Accessibility is a core requirement

- [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
- [ ] Navigate forms list with swipe gestures
- [ ] Each form row reads title and date clearly
- [ ] "+" button has clear label ("Add Form" or similar)
- [ ] Delete button labeled correctly
- [ ] Practice View elements have proper labels
- [ ] Can complete form creation workflow using only VoiceOver:
  - [ ] Tap "+" button via VoiceOver
  - [ ] Enter title and moves via VoiceOver
  - [ ] Save form via VoiceOver
- [ ] Can start and stop practice session using VoiceOver:
  - [ ] Navigate to form and open practice view
  - [ ] Activate Start button
  - [ ] Activate Stop button
- [ ] All interactive elements reachable via VoiceOver gestures

**Expected:** App fully usable with VoiceOver, core workflows completable

---

## Screen Size Tests (Optional)

### iPhone SE (Small Screen)
- [ ] Forms list displays without truncation issues
- [ ] Practice View buttons don't overlap
- [ ] Form editor text fields fully visible
- [ ] Navigation elements sized appropriately

### iPhone 15 Pro Max (Large Screen)
- [ ] Layout uses space effectively
- [ ] No awkward stretching or gaps
- [ ] Text remains readable

**Expected:** UI adapts to different screen sizes

---

## Performance & Stability

### Performance
- [ ] App launches in <2 seconds
- [ ] Form list loads instantly (<500ms)
- [ ] Practice session starts immediately (<200ms for TTS)
- [ ] Voice commands recognized in <1 second
- [ ] No lag when scrolling forms list

### Stability
- [ ] No crashes during 10-minute testing session
- [ ] No memory warnings
- [ ] No UI glitches or visual artifacts
- [ ] Smooth animations throughout

**Expected:** Fast, stable, responsive app

---

## Privacy & Permissions

### First Launch
- [ ] App requests microphone permission for practice mode
- [ ] App requests speech recognition permission
- [ ] Permission prompts have clear explanations
- [ ] App works without permissions (manual mode only)

### Ongoing
- [ ] Microphone only accessed during practice
- [ ] No data leaves device (verify in Settings → Privacy)
- [ ] No analytics or tracking

**Expected:** Privacy-respecting, clear permissions

---

## Regression Checks (After Bug Fixes)

When fixing bugs, add specific regression tests here:

### Example:
- [ ] **Bug #123 Fixed:** Deleting last form now shows empty state
- [ ] **Bug #456 Fixed:** Forms with 200-character moves save correctly

---

## Sign-Off

**Date:** _______________
**Tester:** _______________
**Build:** _______________
**Result:** ☐ Pass  ☐ Fail (note issues below)

**Issues Found:**
```
[List any bugs or issues discovered during testing]
```

**Notes:**
```
[Any additional observations or concerns]
```

---

## Quick Reference: Test Data

Use these standardized test forms for consistency:

**Basic Form:**
```
Title: "Basic Test Form"
Moves:
- Front stance
- Down block
- Step forward
- Middle punch
```

**Edge Case Form:**
```
Title: "形同士 Special Characters & Symbols!"
Moves:
- Move with 特殊 characters
- Very long move: [paste 200-char string]
```

**Minimal Form:**
```
Title: "One Move"
Moves:
- Single move
```
