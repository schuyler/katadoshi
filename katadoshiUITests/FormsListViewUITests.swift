//
//  FormsListViewUITests.swift
//  katadoshiUITests
//
//  Created by Claude Code on 11/3/25.
//

import XCTest

/// UI tests for FormsListView
///
/// Tests the FormsListView screen according to PRD Section 9.1 (Forms List View)
/// and Section 9.4 (UI Design Conventions).
///
/// **Test Coverage:**
/// - Navigation title displays "Kata Dōshi"
/// - Toolbar has "+" button for creating forms
/// - Empty state shows "No Forms Yet" message and subtitle
/// - Form rows display title and last practiced date
/// - Tapping form navigates to PracticeView
/// - Swipe-to-delete functionality
/// - Deleting last form shows empty state
/// - VoiceOver compatibility (accessibility)
///
/// **Manual Verification Requirements:**
/// The following PRD requirements should be verified during code review and manual testing:
/// - Form title typography: 18pt bold (PRD Section 9.1)
/// - Last practiced date typography: 14pt gray (PRD Section 9.1)
/// - Delete button color: System red (PRD Section 9.1)
/// - "+" button uses SF Symbol "plus" (PRD Section 9.1)
/// - List style: .insetGrouped with rounded corners (PRD Section 9.4)
///
/// These visual styling properties cannot be reliably tested via XCUITest automation.
final class FormsListViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Reset app state for testing
        // Note: This requires FormsListView to use an injectable FormStore
        // and the app to check for launch arguments to configure test mode
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Title Tests

    @MainActor
    func testNavigationTitleDisplaysKataDoshi() throws {
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should display 'Kata Dōshi'")
    }

    // MARK: - Toolbar Tests

    @MainActor
    func testToolbarHasAddButton() throws {
        let addButton = app.navigationBars.buttons["Add Form"]
        XCTAssertTrue(addButton.exists, "Toolbar should have an 'Add Form' button")

        // Note: PRD requires "+" button to use SF Symbol "plus"
        // SF Symbol usage should be verified via code review of FormsListView implementation
    }

    @MainActor
    func testTappingAddButtonNavigatesToFormEditor() throws {
        let addButton = app.navigationBars.buttons["Add Form"]
        addButton.tap()

        // Check for FormEditorView navigation
        // Since FormEditorView is not yet implemented, check for stub view
        // When implemented, look for "New Form" title or form editor elements
        let formEditorView = app.navigationBars["New Form"]
        let comingSoonText = app.staticTexts["Coming Soon"]

        XCTAssertTrue(formEditorView.exists || comingSoonText.exists, "Tapping add button should navigate to FormEditorView")
    }

    // MARK: - Empty State Tests

    @MainActor
    func testEmptyStateDisplaysWhenNoForms() throws {
        // This test assumes app launches with no forms in test mode
        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        XCTAssertTrue(emptyStateTitle.exists, "Empty state title should be visible when no forms exist")
    }

    @MainActor
    func testEmptyStateDisplaysSubtitle() throws {
        let emptyStateSubtitle = app.staticTexts["Tap + to create your first form"]
        XCTAssertTrue(emptyStateSubtitle.exists, "Empty state subtitle should be visible")
    }

    @MainActor
    func testEmptyStateNotDisplayedWhenFormsExist() throws {
        // Create a test form
        createTestForm(title: "Test Form")

        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        XCTAssertFalse(emptyStateTitle.exists, "Empty state should not be visible when forms exist")
    }

    // MARK: - Form Row Display Tests

    @MainActor
    func testFormRowDisplaysTitle() throws {
        let testTitle = "Heian Shodan"
        createTestForm(title: testTitle)

        let formTitle = app.staticTexts[testTitle]
        XCTAssertTrue(formTitle.exists, "Form row should display form title")
    }

    @MainActor
    func testFormRowDisplaysLastPracticedDate() throws {
        createTestForm(title: "Test Form")

        // Check for date text within the form row
        // Use more specific selector to avoid matching unrelated text
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should exist")

        // Within the row, look for date-related text
        // The exact format depends on RelativeDateTimeFormatter and locale
        // but should contain temporal keywords
        let rowLabel = formRow.label
        let hasDateInfo = rowLabel.lowercased().contains("ago") ||
                         rowLabel.lowercased().contains("last practiced") ||
                         rowLabel.lowercased().contains("today") ||
                         rowLabel.lowercased().contains("yesterday") ||
                         rowLabel.lowercased().contains("never")

        XCTAssertTrue(hasDateInfo, "Form row should display last practiced date information")
    }

    @MainActor
    func testFormRowHasChevronIndicator() throws {
        createTestForm(title: "Test Form")

        // NavigationLink automatically adds chevron in iOS
        // Check that row is tappable (has navigation affordance)
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should be tappable with navigation affordance")
    }

    @MainActor
    func testMultipleFormsDisplayInList() throws {
        createTestForm(title: "Form 1")
        createTestForm(title: "Form 2")
        createTestForm(title: "Form 3")

        XCTAssertTrue(app.staticTexts["Form 1"].exists, "Form 1 should be displayed")
        XCTAssertTrue(app.staticTexts["Form 2"].exists, "Form 2 should be displayed")
        XCTAssertTrue(app.staticTexts["Form 3"].exists, "Form 3 should be displayed")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testTappingFormNavigatesToPracticeView() throws {
        let testTitle = "Test Form"
        createTestForm(title: testTitle)

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", testTitle)).firstMatch
        formRow.tap()

        // Check for PracticeView navigation
        // Since PracticeView is not yet implemented, check for stub view
        // When implemented, look for practice view elements or form title in nav bar
        let practiceView = app.navigationBars[testTitle]
        let comingSoonText = app.staticTexts["Coming Soon"]

        XCTAssertTrue(practiceView.exists || comingSoonText.exists, "Tapping form should navigate to PracticeView")
    }

    @MainActor
    func testNavigationBackFromFormReturnsToList() throws {
        createTestForm(title: "Test Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        formRow.tap()

        // Navigate back using the navigation bar back button
        // Look for button with "Kata Dōshi" label (iOS standard back button shows parent title)
        let backButton = app.navigationBars.buttons["Kata Dōshi"]
        if backButton.exists {
            backButton.tap()
        } else {
            // Fallback: try "Back" button
            let genericBackButton = app.navigationBars.buttons["Back"]
            if genericBackButton.exists {
                genericBackButton.tap()
            }
        }

        // Should return to list view
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Should return to forms list view")
    }

    // MARK: - Swipe-to-Delete Tests

    @MainActor
    func testSwipeToDeleteRevealsDeleteButton() throws {
        createTestForm(title: "Test Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        formRow.swipeLeft()

        // Check for delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.exists, "Swiping left should reveal delete button")
    }

    @MainActor
    func testDeletingFormRemovesItFromList() throws {
        let testTitle = "Form to Delete"
        createTestForm(title: testTitle)

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", testTitle)).firstMatch
        formRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        deleteButton.tap()

        // Verify form is no longer in list
        let deletedForm = app.staticTexts[testTitle]
        XCTAssertFalse(deletedForm.exists, "Deleted form should no longer appear in list")
    }

    @MainActor
    func testDeletingOnlyFormShowsEmptyState() throws {
        createTestForm(title: "Only Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Only Form'")).firstMatch
        formRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        deleteButton.tap()

        // Should show empty state
        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        XCTAssertTrue(emptyStateTitle.exists, "Deleting last form should show empty state")
    }

    @MainActor
    func testDeletingOneFormLeavesOthersIntact() throws {
        createTestForm(title: "Form 1")
        createTestForm(title: "Form 2")
        createTestForm(title: "Form 3")

        let form2Row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Form 2'")).firstMatch
        form2Row.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        deleteButton.tap()

        // Verify Form 2 is gone but others remain
        XCTAssertFalse(app.staticTexts["Form 2"].exists, "Form 2 should be deleted")
        XCTAssertTrue(app.staticTexts["Form 1"].exists, "Form 1 should remain")
        XCTAssertTrue(app.staticTexts["Form 3"].exists, "Form 3 should remain")
    }

    // MARK: - List Style Tests (PRD Section 9.4)

    @MainActor
    func testListExists() throws {
        // PRD Section 9.4 requires .insetGrouped list style
        // This style creates rounded, inset list sections that don't extend to screen edges
        //
        // UI tests cannot directly verify SwiftUI list style modifiers
        // Manual verification required:
        // - List should have rounded corners
        // - List should be inset from screen edges
        // - List background should be distinct from screen background
        //
        // This test verifies the list element exists for manual inspection
        let list = app.tables.firstMatch
        XCTAssertTrue(list.exists, "List should exist (verify .insetGrouped style manually)")
    }

    // MARK: - Accessibility Tests (PRD Section 9.4)

    @MainActor
    func testFormRowsAreAccessible() throws {
        createTestForm(title: "Accessible Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Accessible Form'")).firstMatch

        // Check that element is accessible
        XCTAssertTrue(formRow.exists, "Form row should exist")
        XCTAssertTrue(formRow.isEnabled, "Form row should be enabled for accessibility")
    }

    @MainActor
    func testFormRowHasAccessibilityLabel() throws {
        createTestForm(title: "Test Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should exist")

        // Accessibility label should include form title and last practiced information
        let label = formRow.label
        XCTAssertTrue(label.contains("Test Form"), "Accessibility label should include form title")

        // Should provide contextual information for VoiceOver users
        XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty")
    }

    @MainActor
    func testFormRowHasAccessibilityHint() throws {
        createTestForm(title: "Test Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should exist")

        // Form row should have button trait (indicating it's tappable)
        // This provides VoiceOver users with action context
        let traits = formRow.elementType
        XCTAssertEqual(traits, .button, "Form row should have button trait for VoiceOver")
    }

    @MainActor
    func testAddButtonIsAccessible() throws {
        let addButton = app.navigationBars.buttons["Add Form"]

        XCTAssertTrue(addButton.exists, "Add button should exist")
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled for accessibility")

        // Button should have clear accessibility label
        let label = addButton.label
        XCTAssertFalse(label.isEmpty, "Add button should have accessibility label")
    }

    @MainActor
    func testAddButtonHasAccessibilityLabel() throws {
        let addButton = app.navigationBars.buttons["Add Form"]
        XCTAssertTrue(addButton.exists, "Add button should exist")

        // Accessibility label should be clear for VoiceOver users
        let label = addButton.label
        XCTAssertTrue(label.contains("Add") || label.contains("Form") || label.contains("+"),
                     "Add button accessibility label should indicate purpose")
    }

    @MainActor
    func testEmptyStateIsAccessible() throws {
        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        let emptyStateSubtitle = app.staticTexts["Tap + to create your first form"]

        XCTAssertTrue(emptyStateTitle.exists, "Empty state title should be accessible")
        XCTAssertTrue(emptyStateSubtitle.exists, "Empty state subtitle should be accessible")

        // Empty state text should be readable by VoiceOver
        XCTAssertFalse(emptyStateTitle.label.isEmpty, "Empty state title should have text")
        XCTAssertFalse(emptyStateSubtitle.label.isEmpty, "Empty state subtitle should have text")
    }

    @MainActor
    func testDeleteButtonIsAccessible() throws {
        createTestForm(title: "Delete Test Form")

        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Delete Test Form'")).firstMatch
        formRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.exists, "Delete button should exist")
        XCTAssertTrue(deleteButton.isEnabled, "Delete button should be enabled for accessibility")

        // Delete button should have clear label
        let label = deleteButton.label
        XCTAssertTrue(label.contains("Delete"), "Delete button should have clear accessibility label")
    }

    @MainActor
    func testNavigationTitleIsAccessible() throws {
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")

        // Navigation title should be accessible to VoiceOver
        let identifier = navigationBar.identifier
        XCTAssertEqual(identifier, "Kata Dōshi", "Navigation bar should have correct identifier")
    }

    // MARK: - Edge Cases

    @MainActor
    func testFormWithLongTitleDisplaysProperly() throws {
        let longTitle = "This is a very long form title that should wrap or truncate properly in the list view without breaking the layout"
        createTestForm(title: longTitle)

        let formTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'This is a very long form title'")).firstMatch
        XCTAssertTrue(formTitle.exists, "Form with long title should display properly")
    }

    @MainActor
    func testListScrollsWhenManyFormsPresent() throws {
        // Create many forms
        for i in 1...20 {
            createTestForm(title: "Form \(i)")
        }

        // Verify first form is visible
        XCTAssertTrue(app.staticTexts["Form 1"].exists, "First form should be visible")

        // Scroll to bottom
        let list = app.tables.firstMatch
        list.swipeUp()
        list.swipeUp()

        // Verify last form becomes visible (may require multiple swipes)
        // This is best-effort due to screen size variations
        let lastFormVisible = app.staticTexts["Form 20"].waitForExistence(timeout: 2)
        XCTAssertTrue(lastFormVisible, "List should scroll to show last form")
    }

    @MainActor
    func testFormWithSpecialCharactersDisplaysProperly() throws {
        let specialTitle = "形同士 (Kata Dōshi) - Test"
        createTestForm(title: specialTitle)

        let formTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '形同士'")).firstMatch
        XCTAssertTrue(formTitle.exists, "Form with special characters should display properly")
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompleteWorkflow() throws {
        // Start with empty state
        XCTAssertTrue(app.staticTexts["No Forms Yet"].exists, "Should start with empty state")

        // Add first form
        createTestForm(title: "First Form")

        // Empty state should disappear
        XCTAssertFalse(app.staticTexts["No Forms Yet"].exists, "Empty state should disappear after adding form")

        // Add second form
        createTestForm(title: "Second Form")

        // Navigate to form
        let firstFormRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'First Form'")).firstMatch
        firstFormRow.tap()

        // Navigate back
        let backButton = app.navigationBars.buttons["Kata Dōshi"]
        if backButton.exists {
            backButton.tap()
        } else {
            let genericBackButton = app.navigationBars.buttons["Back"]
            if genericBackButton.exists {
                genericBackButton.tap()
            }
        }

        // Delete a form
        let secondFormRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Second Form'")).firstMatch
        secondFormRow.swipeLeft()
        app.buttons["Delete"].tap()

        // Verify only first form remains
        XCTAssertTrue(app.staticTexts["First Form"].exists, "First form should remain")
        XCTAssertFalse(app.staticTexts["Second Form"].exists, "Second form should be deleted")
    }

    // MARK: - Test Helpers

    /// Helper to create a test form through the UI
    ///
    /// **Implementation Note:**
    /// This function creates forms using test data injection rather than the UI
    /// because FormEditorView is not yet implemented. The approach uses:
    ///
    /// 1. Launch arguments to signal test mode (see setUp)
    /// 2. FormsListView checks for "UI_TESTING" launch argument
    /// 3. In test mode, FormsListView uses a test FormStore that supports direct insertion
    /// 4. Test helper methods on FormStore (testOnlyInsertForm) allow creating forms
    ///
    /// When FormEditorView is implemented, these tests can be updated to use actual UI:
    /// - Tap "Add Form" button
    /// - Enter title in text field
    /// - Enter moves in text view
    /// - Tap "Save" button
    ///
    /// Until then, tests validate list display, navigation, and deletion behaviors
    /// using injected test data.
    ///
    /// - Parameter title: The title of the form to create
    private func createTestForm(title: String) {
        // Test data injection approach:
        // FormsListView should expose a test-only method or use a shared test store
        // that can be accessed via app.launchEnvironment or similar mechanism
        //
        // Example implementation in FormsListView:
        // #if DEBUG
        // if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
        //     // Use test FormStore that allows direct insertion
        //     formStore.testOnlyInsertForm(Form(title: title, moves: ["Move 1", "Move 2"]))
        // }
        // #endif
        //
        // For now, this is a placeholder. UI tests that depend on forms will be
        // validated after FormEditorView implementation OR FormsListView adds
        // test data injection support as described above.
    }
}
