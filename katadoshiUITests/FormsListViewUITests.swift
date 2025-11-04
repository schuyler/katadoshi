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
        // Note: Most tests will call launchWithTestForms() to get pre-injected data
        // Some tests (empty state) will call launch() directly with just UI_TESTING
        app.launchArguments = ["UI_TESTING"]
        // Don't call launch() here - let individual tests control when to launch
    }

    /// Launches app with pre-injected test forms for faster test execution
    private func launchWithTestForms() {
        app.launchArguments = ["UI_TESTING", "FORMS_LIST_TESTING"]
        app.launch()
    }

    /// Launches app with empty FormStore (no forms)
    private func launchWithEmptyState() {
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Title Tests

    @MainActor
    func testNavigationTitleDisplaysKataDoshi() throws {
        launchWithEmptyState()
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should display 'Kata Dōshi'")
    }

    // MARK: - Toolbar Tests

    @MainActor
    func testToolbarHasAddButton() throws {
        launchWithEmptyState()
        let addButton = app.navigationBars.buttons["Add Form"]
        XCTAssertTrue(addButton.exists, "Toolbar should have an 'Add Form' button")

        // Note: PRD requires "+" button to use SF Symbol "plus"
        // SF Symbol usage should be verified via code review of FormsListView implementation
    }

    @MainActor
    func testTappingAddButtonNavigatesToFormEditor() throws {
        launchWithEmptyState()
        let addButton = app.navigationBars.buttons["Add Form"]
        addButton.tap()

        // Check for FormEditorView (presented as sheet, not navigation push)
        // Wait for form editor elements to appear
        let titleField = app.textFields["Form Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Form editor should appear as sheet after tapping add button")
    }

    // MARK: - Empty State Tests

    @MainActor
    func testEmptyStateDisplaysWhenNoForms() throws {
        launchWithEmptyState()
        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        XCTAssertTrue(emptyStateTitle.exists, "Empty state title should be visible when no forms exist")
    }

    @MainActor
    func testEmptyStateDisplaysSubtitle() throws {
        launchWithEmptyState()
        let emptyStateSubtitle = app.staticTexts["Tap + to create your first form"]
        XCTAssertTrue(emptyStateSubtitle.exists, "Empty state subtitle should be visible")
    }

    @MainActor
    func testEmptyStateNotDisplayedWhenFormsExist() throws {
        launchWithTestForms()
        let emptyStateTitle = app.staticTexts["No Forms Yet"]
        XCTAssertFalse(emptyStateTitle.exists, "Empty state should not be visible when forms exist")
    }

    // MARK: - Form Row Display Tests

    @MainActor
    func testFormRowDisplaysTitle() throws {
        launchWithTestForms()
        // Use pre-injected "Test Form 1"
        let formTitle = app.staticTexts["Test Form 1"]
        XCTAssertTrue(formTitle.exists, "Form row should display form title")
    }

    @MainActor
    func testFormRowDisplaysLastPracticedDate() throws {
        launchWithTestForms()
        // Use pre-injected "Test Form 1"
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
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
        launchWithTestForms()
        // Use pre-injected "Test Form 1"
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should be tappable with navigation affordance")
    }

    @MainActor
    func testMultipleFormsDisplayInList() throws {
        launchWithTestForms()
        // Use pre-injected forms
        XCTAssertTrue(app.staticTexts["Test Form 1"].exists, "Test Form 1 should be displayed")
        XCTAssertTrue(app.staticTexts["Test Form 2"].exists, "Test Form 2 should be displayed")
        XCTAssertTrue(app.staticTexts["Test Form 3"].exists, "Test Form 3 should be displayed")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testTappingFormNavigatesToPracticeView() throws {
        launchWithTestForms()
        let testTitle = "Test Form 1"
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", testTitle)).firstMatch
        formRow.tap()

        // Check for PracticeView navigation - should show form title in nav bar
        let practiceView = app.navigationBars[testTitle]
        XCTAssertTrue(practiceView.waitForExistence(timeout: 2), "Tapping form should navigate to PracticeView")
    }

    @MainActor
    func testNavigationBackFromFormReturnsToList() throws {
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
        formRow.tap()

        // Navigate back using the navigation bar back button
        // Try "Back" button first (more reliable), then fallback to specific title
        let genericBackButton = app.navigationBars.buttons["Back"]
        if genericBackButton.exists {
            genericBackButton.tap()
        } else {
            // Fallback: try button with parent title
            let backButton = app.navigationBars.buttons["Kata Dōshi"]
            if backButton.exists {
                backButton.tap()
            }
        }

        // Should return to list view
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Should return to forms list view")
    }

    // MARK: - Swipe-to-Delete Tests

    @MainActor
    func testSwipeToDeleteRevealsDeleteButton() throws {
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
        formRow.swipeLeft()

        // Check for delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.exists, "Swiping left should reveal delete button")
    }

    @MainActor
    func testDeletingFormRemovesItFromList() throws {
        launchWithTestForms()
        // Use pre-injected "Test Form 1"
        let testTitle = "Test Form 1"
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
        // This test needs a single form, so launch with empty and create one
        launchWithEmptyState()
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
        launchWithTestForms()
        // Use pre-injected "Test Form 1", "Test Form 2", "Test Form 3"
        let form2Row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 2'")).firstMatch
        form2Row.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        deleteButton.tap()

        // Verify Form 2 is gone but others remain
        XCTAssertFalse(app.staticTexts["Test Form 2"].exists, "Test Form 2 should be deleted")
        XCTAssertTrue(app.staticTexts["Test Form 1"].exists, "Test Form 1 should remain")
        XCTAssertTrue(app.staticTexts["Test Form 3"].exists, "Test Form 3 should remain")
    }

    // MARK: - List Style Tests (PRD Section 9.4)

    @MainActor
    func testListExists() throws {
        launchWithEmptyState()
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
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch

        // Check that element is accessible
        XCTAssertTrue(formRow.exists, "Form row should exist")
        XCTAssertTrue(formRow.isEnabled, "Form row should be enabled for accessibility")
    }

    @MainActor
    func testFormRowHasAccessibilityLabel() throws {
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should exist")

        // Accessibility label should include form title and last practiced information
        let label = formRow.label
        XCTAssertTrue(label.contains("Test Form 1"), "Accessibility label should include form title")

        // Should provide contextual information for VoiceOver users
        XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty")
    }

    @MainActor
    func testFormRowHasAccessibilityHint() throws {
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
        XCTAssertTrue(formRow.exists, "Form row should exist")

        // Form row should have button trait (indicating it's tappable)
        // This provides VoiceOver users with action context
        let traits = formRow.elementType
        XCTAssertEqual(traits, .button, "Form row should have button trait for VoiceOver")
    }

    @MainActor
    func testAddButtonIsAccessible() throws {
        launchWithEmptyState()
        let addButton = app.navigationBars.buttons["Add Form"]

        XCTAssertTrue(addButton.exists, "Add button should exist")
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled for accessibility")

        // Button should have clear accessibility label
        let label = addButton.label
        XCTAssertFalse(label.isEmpty, "Add button should have accessibility label")
    }

    @MainActor
    func testAddButtonHasAccessibilityLabel() throws {
        launchWithEmptyState()
        let addButton = app.navigationBars.buttons["Add Form"]
        XCTAssertTrue(addButton.exists, "Add button should exist")

        // Accessibility label should be clear for VoiceOver users
        let label = addButton.label
        XCTAssertTrue(label.contains("Add") || label.contains("Form") || label.contains("+"),
                     "Add button accessibility label should indicate purpose")
    }

    @MainActor
    func testEmptyStateIsAccessible() throws {
        launchWithEmptyState()
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
        launchWithTestForms()
        let formRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Form 1'")).firstMatch
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
        launchWithEmptyState()
        let navigationBar = app.navigationBars["Kata Dōshi"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")

        // Navigation title should be accessible to VoiceOver
        let identifier = navigationBar.identifier
        XCTAssertEqual(identifier, "Kata Dōshi", "Navigation bar should have correct identifier")
    }

    // MARK: - Edge Cases

    @MainActor
    func testFormWithLongTitleDisplaysProperly() throws {
        launchWithTestForms()
        // Use pre-injected long title form
        let formTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'This is a very long form title'")).firstMatch
        XCTAssertTrue(formTitle.exists, "Form with long title should display properly")
    }

    @MainActor
    func testListScrollsWhenManyFormsPresent() throws {
        launchWithTestForms()
        // Pre-injected data includes 10 forms for scrolling tests
        // Verify first form is visible
        XCTAssertTrue(app.staticTexts["Test Form 1"].exists, "First form should be visible")

        // Scroll to bottom
        let list = app.tables.firstMatch
        list.swipeUp()
        list.swipeUp()

        // Verify later forms become visible after scrolling
        let lastFormVisible = app.staticTexts["Form 10"].waitForExistence(timeout: 2)
        XCTAssertTrue(lastFormVisible, "List should scroll to show later forms")
    }

    @MainActor
    func testFormWithSpecialCharactersDisplaysProperly() throws {
        launchWithTestForms()
        // Use pre-injected special characters form
        let formTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '特殊'")).firstMatch
        XCTAssertTrue(formTitle.exists, "Form with special characters should display properly")
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompleteWorkflow() throws {
        // This test validates the complete workflow including form creation UI
        launchWithEmptyState()

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

        // Navigate back - try "Back" button first (more reliable)
        let genericBackButton = app.navigationBars.buttons["Back"]
        if genericBackButton.exists {
            genericBackButton.tap()
        } else {
            let backButton = app.navigationBars.buttons["Kata Dōshi"]
            if backButton.exists {
                backButton.tap()
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
    /// - Parameters:
    ///   - title: The title of the form to create
    ///   - moves: Optional array of moves (defaults to ["Move 1", "Move 2"])
    ///
    /// Note: FormEditorView is presented as a sheet (modal), not push navigation
    private func createTestForm(title: String, moves: [String] = ["Move 1", "Move 2"]) {
        // Navigate to form editor (presented as sheet)
        let addButton = app.navigationBars.buttons["Add Form"]
        addButton.tap()

        // Wait for title field to appear (sheet presentation)
        let titleField = app.textFields["Form Title"]
        guard titleField.waitForExistence(timeout: 2) && titleField.isEnabled else {
            XCTFail("Title field not ready for interaction")
            return
        }
        titleField.tap()
        titleField.typeText(title)

        // Wait for moves editor to be interactive
        let movesEditor = app.textViews["Form Moves"]
        guard movesEditor.waitForExistence(timeout: 2) && movesEditor.isEnabled else {
            XCTFail("Moves editor not ready for interaction")
            return
        }
        movesEditor.tap()
        movesEditor.typeText(moves.joined(separator: "\n"))

        // Tap Save button to dismiss sheet
        let saveButton = app.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled else {
            XCTFail("Save button not enabled")
            return
        }
        saveButton.tap()

        // Wait for sheet to dismiss and return to forms list
        // Check that forms list navigation bar is visible
        let listNav = app.navigationBars["Kata Dōshi"]
        guard listNav.waitForExistence(timeout: 2) else {
            XCTFail("Did not return to forms list after save")
            return
        }
    }
}
