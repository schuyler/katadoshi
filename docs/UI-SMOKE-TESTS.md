# UI Smoke Tests - Retained for CI/CD

**Decision:** Keep only critical path smoke tests for automated CI/CD validation. All detailed UI testing moved to manual QA checklist.

**Rationale:**
- 350+ unit tests provide 100% business logic coverage
- UI tests are slow (4-5 minutes minimum) and brittle
- Manual testing takes 5-10 minutes for comprehensive coverage
- ROI for detailed UI test automation is negative for small app
- Smoke tests catch catastrophic failures only

---

## Smoke Tests to Keep (5 tests, ~30 seconds total)

These tests verify the app isn't completely broken. Run in CI/CD before deployment.

### FormsListView (2 tests)

**1. testNavigationTitleDisplaysKataDoshi**
- Verifies: App launches successfully
- Why keep: Detects app launch failures

**2. testCompleteWorkflow**
- Verifies: Create form → View list → Delete form
- Why keep: Critical path smoke test

### FormEditorView (1 test)

**3. testFormEditorOpensAndCancel** (create if needed)
- Verifies: Can open editor and cancel
- Why keep: Modal presentation works

### PracticeView (2 tests)

**4. testPracticeViewOpens** (create if needed)
- Verifies: Can navigate to practice view
- Why keep: Navigation stack works

**5. testStartButtonExists** (simplify existing)
- Verifies: Practice UI renders
- Why keep: Basic UI smoke test

---

## Tests Removed from Automation

All other tests moved to `MANUAL-QA-CHECKLIST.md`:

### FormsListView (~27 tests removed)
- Detailed accessibility tests
- Edge cases (long titles, special characters)
- Deletion variations
- Scrolling tests
- Navigation back button tests

### FormEditorView (~10-12 tests removed)
- Form validation tests
- Edit mode tests
- Delete confirmation tests
- Field population tests

### PracticeView (~15-20 tests removed)
- State machine transitions
- Voice command tests (require manual testing anyway)
- Move counter tests
- Session flow tests

**Total tests removed:** ~52-59 tests (saves 4-5 minutes per run)

---

## CI/CD Integration

**Before deployment:**
```bash
# Run smoke tests (30 seconds)
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:katadoshiUITests/FormsListViewUITests/testNavigationTitleDisplaysKataDoshi \
  -only-testing:katadoshiUITests/FormsListViewUITests/testCompleteWorkflow \
  -only-testing:katadoshiUITests/FormEditorViewUITests/testFormEditorOpensAndCancel \
  -only-testing:katadoshiUITests/PracticeViewUITests/testPracticeViewOpens \
  -only-testing:katadoshiUITests/PracticeViewUITests/testStartButtonExists

# Run unit tests (fast)
xcodebuild test -project katadoshi.xcodeproj -scheme katadoshi \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:katadoshiTests

# Run manual QA checklist before release
# See: docs/MANUAL-QA-CHECKLIST.md
```

---

## Future Considerations

**If the app grows significantly** (10+ views, complex workflows):
- Re-evaluate UI test automation ROI
- Consider snapshot testing for visual regression
- Evaluate faster UI testing frameworks (KIF, EarlGrey)

**For now:** Smoke tests + comprehensive unit tests + manual QA = optimal balance
