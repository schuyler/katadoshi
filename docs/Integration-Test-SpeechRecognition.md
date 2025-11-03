# Speech Recognition Authorization Integration Tests

## Overview

This document provides manual integration test procedures for SpeechRecognitionService authorization flows. These tests verify behavior that cannot be unit tested due to reliance on system-level microphone permissions.

## Test Environment Requirements

- **Device:** Physical iOS device (permissions don't work reliably in simulator)
- **iOS Version:** 16.0 or later
- **Capabilities:** Ability to modify Settings → Privacy & Security → Microphone
- **Test Data:** Fresh app install capability for "Not Determined" state testing

## Related Documentation

- **PRD Reference:** Section 5.3 (Speech Recognition Service), Section 8.1 (Error Handling)
- **Implementation:** `katadoshi/Services/SpeechRecognitionService.swift`
- **Unit Tests:** `katadoshiTests/SpeechRecognitionServiceTests.swift` (13 disabled tests)

---

## Test Cases

### TC-SR-AUTH-01: First Launch Permission Request

**Objective:** Verify permission alert appears when microphone access is not yet determined

**Prerequisites:**
- Fresh app install OR reset permissions via Settings → General → Transfer or Reset iPhone → Reset Location & Privacy
- Microphone permission status: Not Determined

**Test Steps:**
1. Launch Kata Dōshi app
2. Navigate to practice mode (tap a form, then "Start Practice")
3. App calls `SpeechRecognitionService.startListening()`

**Expected Results:**
- iOS system permission alert appears
- Alert title: "Kata Dōshi Would Like to Access the Microphone"
- Alert message: Explains why microphone access is needed
- Two buttons: "Don't Allow" and "OK"
- App waits for user response before proceeding
- Practice mode does not start until permission granted

**Pass Criteria:** ✓ System alert appears with correct text and options

---

### TC-SR-AUTH-02: Permission Granted Flow

**Objective:** Verify service starts correctly when user grants permission

**Prerequisites:**
- Continue from TC-SR-AUTH-01
- OR manually set Settings → Privacy & Security → Microphone → Kata Dōshi = ON

**Test Steps:**
1. On permission alert, tap "OK" (or start practice if permission already granted)
2. Observe practice view behavior

**Expected Results:**
- Alert dismisses immediately
- Practice view shows "Listening..." or similar indicator
- `SpeechRecognitionService.isListening` property = `true`
- Service begins recognizing voice commands
- No error callbacks fired (`onPermissionDenied` NOT called)

**Pass Criteria:** ✓ Practice starts successfully and recognizes voice commands

---

### TC-SR-AUTH-03: Permission Denied Behavior

**Objective:** Verify correct handling when user denies microphone permission

**Prerequisites:**
- Settings → Privacy & Security → Microphone → Kata Dōshi = OFF
- (Toggle OFF if currently ON, or tap "Don't Allow" on first launch)

**Test Steps:**
1. Launch app
2. Navigate to practice mode
3. Tap "Start Practice"
4. Observe behavior

**Expected Results:**
- NO system permission alert appears (permission already determined)
- `onPermissionDenied` callback fires
- App displays error alert per PRD Section 8.1:
  - Title: "Microphone Access Required" (or similar)
  - Message: Explains need for microphone to recognize voice commands
  - Button: "Open Settings" (deep links to Settings app)
  - Button: "Cancel" (dismisses alert)
- Practice mode does NOT start
- `SpeechRecognitionService.isListening` = `false`
- Audio engine does NOT start

**Pass Criteria:** ✓ Error alert shown, practice blocked, user directed to Settings

---

### TC-SR-AUTH-04: Open Settings Deep Link

**Objective:** Verify "Open Settings" button correctly navigates to app settings

**Prerequisites:**
- Continue from TC-SR-AUTH-03
- Permission denied state active

**Test Steps:**
1. On error alert, tap "Open Settings"
2. Observe navigation

**Expected Results:**
- Settings app opens
- Directly navigates to: Settings → Kata Dōshi
- Microphone toggle visible and currently OFF
- User can toggle ON to grant permission

**Pass Criteria:** ✓ Settings app opens to correct location

---

### TC-SR-AUTH-05: Permission Re-granted

**Objective:** Verify service works after user grants permission following denial

**Prerequisites:**
- Permission was previously denied (TC-SR-AUTH-03)

**Test Steps:**
1. Go to Settings → Privacy & Security → Microphone → Kata Dōshi
2. Toggle microphone permission ON
3. Return to Kata Dōshi app (use App Switcher, don't force quit)
4. Navigate to practice mode
5. Tap "Start Practice"

**Expected Results:**
- NO permission alert (already determined as authorized)
- Practice starts immediately
- `SpeechRecognitionService.isListening` = `true`
- Service recognizes voice commands
- No error messages shown

**Pass Criteria:** ✓ Practice works normally after permission granted

---

### TC-SR-AUTH-06: Permission Restricted (Parental Controls)

**Objective:** Verify handling when microphone is restricted by Screen Time

**Prerequisites:**
- Enable Screen Time → Content & Privacy Restrictions → Allow Changes to Microphone = "Don't Allow"
- OR device managed by MDM with microphone restrictions

**Test Steps:**
1. Launch app
2. Navigate to practice mode
3. Tap "Start Practice"

**Expected Results:**
- Similar behavior to TC-SR-AUTH-03 (permission denied)
- `onPermissionDenied` callback fires
- Error alert shown explaining restricted access
- Practice mode does NOT start
- "Open Settings" button may show different behavior (cannot change restricted setting)

**Pass Criteria:** ✓ Service handles restricted state same as denied state

---

### TC-SR-AUTH-07: Background/Foreground Transition

**Objective:** Verify service handles permission changes while app is backgrounded

**Prerequisites:**
- App running with permission granted
- Practice session active

**Test Steps:**
1. Start practice session (service listening)
2. Background app (Home button or gesture)
3. Go to Settings → Privacy & Security → Microphone → Kata Dōshi = OFF
4. Return to app via App Switcher

**Expected Results:**
- Service detects permission change
- Practice session stops gracefully
- Error message shown on foreground
- User prompted to re-enable permission

**Pass Criteria:** ✓ Service detects permission revocation and handles gracefully

**Note:** This is edge case behavior - may require app relaunch to detect change

---

### TC-SR-AUTH-08: Recognizer Unavailable

**Objective:** Verify handling when speech recognizer is unavailable (not permission-related)

**Prerequisites:**
- Microphone permission granted
- Test on device/simulator where `SFSpeechRecognizer` may be unavailable (rare)

**Test Steps:**
1. Start practice session
2. Observe behavior if recognizer initialization fails

**Expected Results:**
- `onRecognitionUnavailable` callback fires (NOT `onPermissionDenied`)
- Error message indicates speech recognition unavailable
- Different message from permission errors
- Manual stop button remains available

**Pass Criteria:** ✓ Distinguishes unavailable recognizer from permission issues

---

## Test Execution Log

Use this template to record test results:

```
Test Date: _______________
iOS Version: _______________
Device Model: _______________
Tester: _______________

| Test Case | Pass/Fail | Notes |
|-----------|-----------|-------|
| TC-SR-AUTH-01 | [ ] | |
| TC-SR-AUTH-02 | [ ] | |
| TC-SR-AUTH-03 | [ ] | |
| TC-SR-AUTH-04 | [ ] | |
| TC-SR-AUTH-05 | [ ] | |
| TC-SR-AUTH-06 | [ ] | |
| TC-SR-AUTH-07 | [ ] | |
| TC-SR-AUTH-08 | [ ] | |

Overall Result: [ ] PASS [ ] FAIL

Defects Found:
-
-
```

## Troubleshooting

### Permission Alert Not Appearing

**Symptom:** No system alert on first launch
**Cause:** Permission already determined (cached state)
**Fix:** Settings → General → Transfer or Reset iPhone → Reset Location & Privacy

### Service Won't Start Even With Permission

**Symptom:** Practice mode shows error despite microphone permission ON
**Possible Causes:**
1. Speech recognition permission separate from microphone (check `SFSpeechRecognizer.authorizationStatus()`)
2. Recognizer unavailable for device locale
3. App needs restart after permission change

**Debug:** Use Speech Test Harness (Debug menu) to check authorization status

### Simulator vs. Device Differences

**Known Issues:**
- Simulator may not reliably show permission alerts
- Speech recognition often fails in simulator
- Always test authorization flows on physical device

## Automation Potential

While these tests are currently manual, future automation options include:

1. **XCUITest:** Can detect system alerts and tap buttons (limited permission control)
2. **Test Harness View:** Debug menu for manual verification (implemented in app)
3. **UI Tests:** Can verify error messages and settings deep links

See `katadoshi/Debug/SpeechTestHarnessView.swift` for developer testing tools.

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-03 | 1.0 | Initial integration test specification | Claude Code |
