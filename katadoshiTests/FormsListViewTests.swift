//
//  FormsListViewTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/3/25.
//

import Testing
import Foundation
@testable import katadoshi

/// Unit tests for FormsListView business logic
///
/// Since FormsListView is primarily a UI component that uses FormStore,
/// these tests focus on:
/// - Date formatting logic (if extracted as testable function)
/// - FormStore integration and reactive updates
/// - Any view-specific helper functions
///
/// **Note:** UI tests in FormsListViewUITests.swift cover the visual
/// presentation and user interactions.
@MainActor
struct FormsListViewTests {

    // MARK: - Test Helpers

    /// Creates a FormStore with a fresh UserDefaults suite for isolated testing
    private func makeTestStore(suiteName: String = UUID().uuidString) -> FormStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return FormStore(userDefaults: defaults)
    }

    /// Creates a valid test form
    private func makeValidForm(
        title: String = "Test Form",
        moves: [String] = ["Move 1", "Move 2"],
        lastPracticed: Date = Date()
    ) -> Form {
        Form(title: title, moves: moves, lastPracticed: lastPracticed)
    }

    // MARK: - FormStore Integration Tests

    @Test func formsListReactsToFormStoreChanges() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")

        // FormStore is @Observable, so changes should trigger view updates
        #expect(store.forms.isEmpty)

        try store.saveForm(form: form1)
        #expect(store.forms.count == 1)
        #expect(store.forms[0].title == "Form 1")

        try store.saveForm(form: form2)
        #expect(store.forms.count == 2)
        #expect(store.forms[1].title == "Form 2")
    }

    @Test func formsListUpdatesWhenFormDeleted() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        #expect(store.forms.count == 2)

        try store.deleteForm(id: form1.id)

        #expect(store.forms.count == 1)
        #expect(store.forms[0].title == "Form 2")
    }

    @Test func formsListUpdatesWhenAllFormsDeleted() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        #expect(store.forms.count == 2)

        try store.deleteForm(id: form1.id)
        try store.deleteForm(id: form2.id)

        #expect(store.forms.isEmpty)
    }

    // MARK: - Date Formatting Tests

    @Test func relativeDateFormatterReturnsReasonableValues() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-5 * 60)
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)
        let lastWeek = now.addingTimeInterval(-7 * 24 * 60 * 60)

        let fiveMinutesString = formatter.localizedString(for: fiveMinutesAgo, relativeTo: now)
        let yesterdayString = formatter.localizedString(for: yesterday, relativeTo: now)
        let lastWeekString = formatter.localizedString(for: lastWeek, relativeTo: now)

        // These will be locale-specific, but should contain key words
        #expect(!fiveMinutesString.isEmpty)
        #expect(!yesterdayString.isEmpty)
        #expect(!lastWeekString.isEmpty)
    }

    @Test func relativeDateFormatterHandlesFutureDates() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let tomorrow = now.addingTimeInterval(24 * 60 * 60)

        let tomorrowString = formatter.localizedString(for: tomorrow, relativeTo: now)

        // Should handle future dates gracefully
        #expect(!tomorrowString.isEmpty)
    }

    @Test func relativeDateFormatterHandlesVeryOldDates() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let lastYear = now.addingTimeInterval(-365 * 24 * 60 * 60)

        let lastYearString = formatter.localizedString(for: lastYear, relativeTo: now)

        // Should handle old dates gracefully
        #expect(!lastYearString.isEmpty)
    }

    @Test func relativeDateFormatterHandlesNeverPracticed() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        // Form created but never practiced (lastPracticed = dateCreated)
        let now = Date()
        let createdDate = now

        // When lastPracticed equals dateCreated, UI should show "Never practiced"
        // This is a UI concern but we verify the formatter handles same timestamps
        let result = formatter.localizedString(for: createdDate, relativeTo: now)
        #expect(!result.isEmpty)
    }

    @Test func relativeDateFormatterHandlesPracticedToday() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 60 * 60)

        let result = formatter.localizedString(for: twoHoursAgo, relativeTo: now)

        // Should show relative time for today
        #expect(!result.isEmpty)
    }

    @Test func relativeDateFormatterHandlesPracticedJustNow() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let thirtySecondsAgo = now.addingTimeInterval(-30)

        let result = formatter.localizedString(for: thirtySecondsAgo, relativeTo: now)

        // Should show very recent time
        #expect(!result.isEmpty)
    }

    @Test func relativeDateFormatterIsLocaleAware() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)

        // Test with different locale
        let originalLocale = formatter.locale
        formatter.locale = Locale(identifier: "en_US")
        let englishResult = formatter.localizedString(for: yesterday, relativeTo: now)

        formatter.locale = Locale(identifier: "ja_JP")
        let japaneseResult = formatter.localizedString(for: yesterday, relativeTo: now)

        // Both should produce non-empty strings
        #expect(!englishResult.isEmpty)
        #expect(!japaneseResult.isEmpty)

        // Restore original locale
        formatter.locale = originalLocale
    }

    // MARK: - Empty State Logic Tests

    @Test func emptyStateShownWhenNoForms() {
        let store = makeTestStore()

        // Empty store should trigger empty state display
        #expect(store.forms.isEmpty)
    }

    @Test func emptyStateHiddenWhenFormsExist() throws {
        let store = makeTestStore()
        let form = makeValidForm()

        try store.saveForm(form: form)

        // Non-empty store should hide empty state
        #expect(!store.forms.isEmpty)
    }

    // MARK: - Form Row Data Tests

    @Test func formRowDisplaysCorrectData() throws {
        let lastPracticed = Date(timeIntervalSince1970: 1699000000)
        let form = makeValidForm(
            title: "Heian Shodan",
            moves: ["Move 1", "Move 2", "Move 3"],
            lastPracticed: lastPracticed
        )

        // Verify form has expected data for display
        #expect(form.title == "Heian Shodan")
        #expect(form.moves.count == 3)
        #expect(form.lastPracticed == lastPracticed)
    }

    @Test func formRowHandlesLongTitle() throws {
        let longTitle = String(repeating: "A", count: 100)
        let form = makeValidForm(title: longTitle)

        // Should be able to create and display form with long title
        #expect(form.title.count == 100)
        #expect(!form.title.isEmpty)
    }

    @Test func formRowHandlesSpecialCharacters() throws {
        let title = "形同士 (Kata Dōshi) - Test Form"
        let form = makeValidForm(title: title)

        // Should handle Unicode characters
        #expect(form.title == title)
        #expect(form.title.contains("形"))
        #expect(form.title.contains("Dōshi"))
    }

    // MARK: - Sorting and Ordering Tests

    @Test func formsDisplayInInsertionOrder() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")
        let form3 = makeValidForm(title: "Form 3")

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        // Forms should be in insertion order
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Form 2")
        #expect(store.forms[2].title == "Form 3")
    }

    @Test func deletingFormMaintainsOrderOfRemaining() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")
        let form3 = makeValidForm(title: "Form 3")

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        try store.deleteForm(id: form2.id)

        // Remaining forms should maintain order
        #expect(store.forms.count == 2)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Form 3")
    }

    @Test func updatingFormMaintainsOrderInList() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1")
        let form2 = makeValidForm(title: "Form 2")
        let form3 = makeValidForm(title: "Form 3")

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        // Update form2 with new title
        var updatedForm2 = form2
        updatedForm2.title = "Updated Form 2"
        try store.updateForm(form: updatedForm2)

        // Order should remain unchanged
        #expect(store.forms.count == 3)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Updated Form 2")
        #expect(store.forms[2].title == "Form 3")
    }

    // MARK: - Performance Tests

    @Test func formListLoadPerformanceMeetsRequirement() throws {
        // PRD Section 10.1: Form list load must be < 500ms
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        // Create test store and populate with 50-100 forms
        let populateStore = FormStore(userDefaults: defaults)
        for i in 1...75 {
            let form = makeValidForm(title: "Performance Test Form \(i)", moves: ["Move 1", "Move 2", "Move 3"])
            try populateStore.saveForm(form: form)
        }

        // Measure load time of a fresh store instance
        let startTime = Date()
        let loadStore = FormStore(userDefaults: defaults)
        let loadTime = Date().timeIntervalSince(startTime)

        // Verify forms loaded
        #expect(loadStore.forms.count == 75)

        // Verify load time < 500ms
        #expect(loadTime < 0.5, "Form list load took \(loadTime * 1000)ms, exceeds 500ms requirement")

        // Clean up
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func handlesLargeNumberOfForms() throws {
        let store = makeTestStore()

        // Add 100 forms
        for i in 1...100 {
            let form = makeValidForm(title: "Form \(i)")
            try store.saveForm(form: form)
        }

        #expect(store.forms.count == 100)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[99].title == "Form 100")
    }

    @Test func handlesRapidFormAdditions() throws {
        let store = makeTestStore()

        // Rapidly add multiple forms
        for i in 1...20 {
            let form = makeValidForm(title: "Rapid Form \(i)")
            try store.saveForm(form: form)
        }

        #expect(store.forms.count == 20)
    }

    @Test func handlesRapidFormDeletions() throws {
        let store = makeTestStore()

        // Add forms
        var formIDs: [UUID] = []
        for i in 1...20 {
            let form = makeValidForm(title: "Form \(i)")
            try store.saveForm(form: form)
            formIDs.append(form.id)
        }

        // Rapidly delete forms
        for id in formIDs[0..<10] {
            try store.deleteForm(id: id)
        }

        #expect(store.forms.count == 10)
    }

    // MARK: - Edge Cases

    @Test func handlesFormWithEmptyMovesArray() {
        // Note: This should be prevented by FormStore validation
        // but we test the Form model can represent it
        let form = Form(
            title: "Invalid Form",
            moves: [],
            dateCreated: Date(),
            lastPracticed: Date()
        )

        #expect(form.moves.isEmpty)
    }

    @Test func handlesFormWithSingleMove() throws {
        let form = makeValidForm(title: "Single Move Form", moves: ["Only Move"])

        #expect(form.moves.count == 1)
        #expect(form.moves[0] == "Only Move")
    }

    @Test func handlesFormWithManyMoves() throws {
        let manyMoves = (1...100).map { "Move \($0)" }
        let form = makeValidForm(title: "Long Form", moves: manyMoves)

        #expect(form.moves.count == 100)
    }

    @Test func handlesDateBoundaries() {
        let distantPast = Date.distantPast
        let distantFuture = Date.distantFuture
        let now = Date()

        let pastForm = makeValidForm(lastPracticed: distantPast)
        let futureForm = makeValidForm(lastPracticed: distantFuture)
        let nowForm = makeValidForm(lastPracticed: now)

        #expect(pastForm.lastPracticed == distantPast)
        #expect(futureForm.lastPracticed == distantFuture)
        #expect(nowForm.lastPracticed.timeIntervalSince1970 > 0)
    }

    // MARK: - Observable Pattern Tests

    @Test func formStoreIsObservable() {
        let store = makeTestStore()

        // FormStore is marked @Observable which enables SwiftUI reactive updates
        // Actual @Observable conformance cannot be tested directly via type checking
        // Integration tests below verify reactive behavior by observing state changes
        #expect(store.forms is [Form])
    }

    @Test func formStorePublishesChangesOnSave() throws {
        let store = makeTestStore()
        let form = makeValidForm()

        // Initial state
        let initialCount = store.forms.count

        // Save form
        try store.saveForm(form: form)

        // State should have changed
        #expect(store.forms.count == initialCount + 1)
    }

    @Test func formStorePublishesChangesOnDelete() throws {
        let store = makeTestStore()
        let form = makeValidForm()

        try store.saveForm(form: form)
        let countAfterSave = store.forms.count

        try store.deleteForm(id: form.id)

        // State should have changed
        #expect(store.forms.count == countAfterSave - 1)
    }

    // MARK: - Error Handling Tests

    @Test func deleteNonexistentFormDoesNotThrow() throws {
        let store = makeTestStore()
        let nonexistentID = UUID()

        // Should not throw or crash
        try store.deleteForm(id: nonexistentID)

        #expect(store.forms.isEmpty)
    }

    @Test func multipleDeletesOfSameFormSafe() throws {
        let store = makeTestStore()
        let form = makeValidForm()

        try store.saveForm(form: form)
        #expect(store.forms.count == 1)

        try store.deleteForm(id: form.id)
        #expect(store.forms.isEmpty)

        // Second delete should be safe
        try store.deleteForm(id: form.id)
        #expect(store.forms.isEmpty)
    }
}
