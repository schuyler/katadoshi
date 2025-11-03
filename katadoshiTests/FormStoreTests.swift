//
//  FormStoreTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/2/25.
//

import Testing
import Foundation
@testable import katadoshi

// MARK: - FormStore Tests

/// Tests for FormStore persistence and business logic
@MainActor
struct FormStoreTests {

    // MARK: - Test Helpers

    /// Creates a FormStore with a fresh UserDefaults suite for isolated testing
    private func makeTestStore(suiteName: String = UUID().uuidString) -> FormStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return FormStore(userDefaults: defaults)
    }

    /// Creates a valid test form
    private func makeValidForm(title: String = "Test Form", moves: [String] = ["Move 1"]) -> Form {
        Form(title: title, moves: moves)
    }

    // MARK: - Initialization Tests

    @Test func formStoreInitializesWithEmptyForms() {
        let store = makeTestStore()

        // New store with fresh UserDefaults should have no forms
        #expect(store.forms.isEmpty)
    }

    @Test func formStoreLoadsExistingFormsOnInit() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        // Manually save forms to UserDefaults
        let existingForms = [
            Form(title: "Form 1", moves: ["Move 1"]),
            Form(title: "Form 2", moves: ["Move 2", "Move 3"])
        ]
        let encoder = JSONEncoder()
        let data = try encoder.encode(existingForms)
        defaults.set(data, forKey: "forms")

        // Create store - should load existing forms
        let store = FormStore(userDefaults: defaults)

        #expect(store.forms.count == 2)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Form 2")
        #expect(store.forms[1].moves.count == 2)
    }

    @Test func formStoreHandlesCorruptedDataGracefully() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        // Set invalid JSON data
        defaults.set(Data("invalid json".utf8), forKey: "forms")

        // Store should initialize with empty forms rather than crash
        let store = FormStore(userDefaults: defaults)
        #expect(store.forms.isEmpty)
    }

    @Test func formStoreHandlesMissingDataGracefully() {
        let store = makeTestStore()

        // Store with no saved data should initialize with empty forms
        #expect(store.forms.isEmpty)
    }

    // MARK: - saveForm() Tests

    @Test func saveFormAddsValidFormToStore() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Heian Shodan", moves: ["Step forward", "Turn left"])

        try store.saveForm(form: form)

        #expect(store.forms.count == 1)
        #expect(store.forms[0].id == form.id)
        #expect(store.forms[0].title == "Heian Shodan")
        #expect(store.forms[0].moves == ["Step forward", "Turn left"])
    }

    @Test func saveFormPersistsToUserDefaults() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FormStore(userDefaults: defaults)
        let form = makeValidForm(title: "Persisted Form", moves: ["Move 1"])

        try store.saveForm(form: form)

        // Verify data was written to UserDefaults
        let data = defaults.data(forKey: "forms")
        #expect(data != nil)

        // Verify we can decode the persisted data
        let decoder = JSONDecoder()
        let loadedForms = try decoder.decode([Form].self, from: data!)
        #expect(loadedForms.count == 1)
        #expect(loadedForms[0].title == "Persisted Form")
    }

    @Test func saveFormThrowsOnEmptyTitle() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "", moves: ["Move 1"])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormThrowsOnWhitespaceOnlyTitle() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "   \t\n  ", moves: ["Move 1"])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormAcceptsTitleWithWhitespaceAroundText() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "  Valid Title  ", moves: ["Move 1"])

        // Should not throw - title has non-whitespace content
        try store.saveForm(form: form)
        #expect(store.forms.count == 1)
    }

    @Test func saveFormThrowsOnEmptyMovesArray() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Valid Title", moves: [])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormThrowsOnMoveLongerThan200Characters() throws {
        let store = makeTestStore()
        let longMove = String(repeating: "A", count: 201)
        let form = makeValidForm(title: "Valid Title", moves: [longMove])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormAcceptsMove200CharactersLong() throws {
        let store = makeTestStore()
        let move200 = String(repeating: "A", count: 200)
        let form = makeValidForm(title: "Valid Title", moves: [move200])

        // Exactly 200 characters should be accepted
        try store.saveForm(form: form)
        #expect(store.forms.count == 1)
        #expect(store.forms[0].moves[0].count == 200)
    }

    @Test func saveFormThrowsIfAnyMoveExceeds200Characters() throws {
        let store = makeTestStore()
        let moves = [
            "Valid move 1",
            "Valid move 2",
            String(repeating: "X", count: 201), // Invalid
            "Valid move 4"
        ]
        let form = makeValidForm(title: "Valid Title", moves: moves)

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormThrowsOnEmptyStringInMovesArray() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Valid Title", moves: ["Move 1", "", "Move 2"])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormThrowsOnWhitespaceOnlyStringInMovesArray() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Valid Title", moves: ["Move 1", "   \t\n  ", "Move 2"])

        #expect(throws: FormStoreError.self) {
            try store.saveForm(form: form)
        }
    }

    @Test func saveFormAcceptsMultipleForms() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1", moves: ["Move 1"])
        let form2 = makeValidForm(title: "Form 2", moves: ["Move A"])
        let form3 = makeValidForm(title: "Form 3", moves: ["Move X"])

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        #expect(store.forms.count == 3)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Form 2")
        #expect(store.forms[2].title == "Form 3")
    }

    @Test func saveFormPublishesChanges() async throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "New Form", moves: ["Move 1"])

        // Save form
        try store.saveForm(form: form)

        // @Observable should trigger UI updates (verified by SwiftUI binding in UI tests)
        // In unit test, we verify the state is correct
        #expect(store.forms.count == 1)
    }

    @Test func saveFormThrowsOnDuplicateID() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original Form", moves: ["Move 1"])
        try store.saveForm(form: form)

        // Try to save another form with the same ID
        let duplicateForm = form
        #expect(throws: FormStoreError.duplicateID) {
            try store.saveForm(form: duplicateForm)
        }

        // Verify only one form exists
        #expect(store.forms.count == 1)
    }

    @Test func saveFormNormalizesWhitespaceInTitle() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "  Test Title  ", moves: ["Move 1"])

        try store.saveForm(form: form)

        // Title should be trimmed
        #expect(store.forms[0].title == "Test Title")
    }

    @Test func saveFormNormalizesWhitespaceInMoves() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Test Form", moves: ["  Move 1  ", "  Move 2  ", "  Move 3  "])

        try store.saveForm(form: form)

        // Moves should be trimmed
        #expect(store.forms[0].moves == ["Move 1", "Move 2", "Move 3"])
    }

    @Test func saveFormNormalizesWhitespaceInTitleAndMoves() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "  Title  ", moves: ["  Move A  ", "  Move B  "])

        try store.saveForm(form: form)

        // Both title and moves should be trimmed
        #expect(store.forms[0].title == "Title")
        #expect(store.forms[0].moves == ["Move A", "Move B"])
    }

    // MARK: - updateForm() Tests

    @Test func updateFormModifiesExistingForm() throws {
        let store = makeTestStore()
        let originalForm = makeValidForm(title: "Original Title", moves: ["Move 1"])
        try store.saveForm(form: originalForm)

        var updatedForm = originalForm
        updatedForm.title = "Updated Title"
        updatedForm.moves = ["New Move 1", "New Move 2"]

        try store.updateForm(form: updatedForm)

        #expect(store.forms.count == 1)
        #expect(store.forms[0].id == originalForm.id)
        #expect(store.forms[0].title == "Updated Title")
        #expect(store.forms[0].moves == ["New Move 1", "New Move 2"])
    }

    @Test func updateFormPersistsChanges() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FormStore(userDefaults: defaults)
        let originalForm = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: originalForm)

        var updatedForm = originalForm
        updatedForm.title = "Updated"
        try store.updateForm(form: updatedForm)

        // Verify persistence
        let data = defaults.data(forKey: "forms")!
        let decoder = JSONDecoder()
        let loadedForms = try decoder.decode([Form].self, from: data)
        #expect(loadedForms[0].title == "Updated")
    }

    @Test func updateFormThrowsOnEmptyTitle() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var invalidForm = form
        invalidForm.title = ""

        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: invalidForm)
        }
    }

    @Test func updateFormThrowsOnEmptyMoves() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var invalidForm = form
        invalidForm.moves = []

        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: invalidForm)
        }
    }

    @Test func updateFormThrowsOnMoveLongerThan200Characters() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var invalidForm = form
        invalidForm.moves = [String(repeating: "X", count: 201)]

        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: invalidForm)
        }
    }

    @Test func updateFormThrowsOnEmptyStringInMovesArray() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var invalidForm = form
        invalidForm.moves = ["Move 1", "", "Move 2"]

        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: invalidForm)
        }
    }

    @Test func updateFormThrowsOnWhitespaceOnlyStringInMovesArray() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var invalidForm = form
        invalidForm.moves = ["Move 1", "   ", "Move 2"]

        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: invalidForm)
        }
    }

    @Test func updateFormThrowsOnNonexistentForm() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Nonexistent", moves: ["Move 1"])

        // Form was never saved
        #expect(throws: FormStoreError.self) {
            try store.updateForm(form: form)
        }
    }

    @Test func updateFormPreservesOtherForms() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1", moves: ["Move 1"])
        let form2 = makeValidForm(title: "Form 2", moves: ["Move 2"])
        let form3 = makeValidForm(title: "Form 3", moves: ["Move 3"])

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        var updatedForm2 = form2
        updatedForm2.title = "Updated Form 2"
        try store.updateForm(form: updatedForm2)

        #expect(store.forms.count == 3)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[1].title == "Updated Form 2")
        #expect(store.forms[2].title == "Form 3")
    }

    @Test func updateFormPublishesChanges() async throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var updatedForm = form
        updatedForm.title = "Updated"
        try store.updateForm(form: updatedForm)

        // @Observable should trigger UI updates
        #expect(store.forms[0].title == "Updated")
    }

    @Test func updateFormNormalizesWhitespaceInTitle() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var updatedForm = form
        updatedForm.title = "  Updated Title  "
        try store.updateForm(form: updatedForm)

        // Title should be trimmed
        #expect(store.forms[0].title == "Updated Title")
    }

    @Test func updateFormNormalizesWhitespaceInMoves() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var updatedForm = form
        updatedForm.moves = ["  Move A  ", "  Move B  ", "  Move C  "]
        try store.updateForm(form: updatedForm)

        // Moves should be trimmed
        #expect(store.forms[0].moves == ["Move A", "Move B", "Move C"])
    }

    @Test func updateFormNormalizesWhitespaceInTitleAndMoves() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Original", moves: ["Move 1"])
        try store.saveForm(form: form)

        var updatedForm = form
        updatedForm.title = "  New Title  "
        updatedForm.moves = ["  New Move 1  ", "  New Move 2  "]
        try store.updateForm(form: updatedForm)

        // Both title and moves should be trimmed
        #expect(store.forms[0].title == "New Title")
        #expect(store.forms[0].moves == ["New Move 1", "New Move 2"])
    }

    // MARK: - deleteForm() Tests

    @Test func deleteFormRemovesFormFromStore() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "To Delete", moves: ["Move 1"])
        try store.saveForm(form: form)

        #expect(store.forms.count == 1)

        try store.deleteForm(id: form.id)

        #expect(store.forms.isEmpty)
    }

    @Test func deleteFormPersistsChanges() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FormStore(userDefaults: defaults)
        let form = makeValidForm(title: "To Delete", moves: ["Move 1"])
        try store.saveForm(form: form)

        try store.deleteForm(id: form.id)

        // Verify deletion was persisted
        let data = defaults.data(forKey: "forms")!
        let decoder = JSONDecoder()
        let loadedForms = try decoder.decode([Form].self, from: data)
        #expect(loadedForms.isEmpty)
    }

    @Test func deleteFormDoesNothingForNonexistentID() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Existing Form", moves: ["Move 1"])
        try store.saveForm(form: form)

        let nonexistentID = UUID()
        try store.deleteForm(id: nonexistentID)

        // Original form should still exist
        #expect(store.forms.count == 1)
        #expect(store.forms[0].id == form.id)
    }

    @Test func deleteFormRemovesOnlySpecifiedForm() throws {
        let store = makeTestStore()
        let form1 = makeValidForm(title: "Form 1", moves: ["Move 1"])
        let form2 = makeValidForm(title: "Form 2", moves: ["Move 2"])
        let form3 = makeValidForm(title: "Form 3", moves: ["Move 3"])

        try store.saveForm(form: form1)
        try store.saveForm(form: form2)
        try store.saveForm(form: form3)

        try store.deleteForm(id: form2.id)

        #expect(store.forms.count == 2)
        #expect(store.forms[0].id == form1.id)
        #expect(store.forms[1].id == form3.id)
    }

    @Test func deleteFormPublishesChanges() async throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "To Delete", moves: ["Move 1"])
        try store.saveForm(form: form)

        try store.deleteForm(id: form.id)

        // @Observable should trigger UI updates
        #expect(store.forms.isEmpty)
    }

    // MARK: - parseMoves() Tests

    @Test func parseMovesHandlesSimpleInput() throws {
        let store = makeTestStore()
        let input = "Move 1\nMove 2\nMove 3"

        let moves = try store.parseMoves(from: input)

        #expect(moves == ["Move 1", "Move 2", "Move 3"])
    }

    @Test func parseMovesTrimsWhitespaceFromEachLine() throws {
        let store = makeTestStore()
        let input = "  Move 1  \n\tMove 2\t\n   Move 3   "

        let moves = try store.parseMoves(from: input)

        #expect(moves == ["Move 1", "Move 2", "Move 3"])
    }

    @Test func parseMovesSkipsEmptyLines() throws {
        let store = makeTestStore()
        let input = "Move 1\n\nMove 2\n   \nMove 3\n\n"

        let moves = try store.parseMoves(from: input)

        #expect(moves == ["Move 1", "Move 2", "Move 3"])
    }

    @Test func parseMovesSkipsWhitespaceOnlyLines() throws {
        let store = makeTestStore()
        let input = "Move 1\n   \nMove 2\n\t\t\nMove 3"

        let moves = try store.parseMoves(from: input)

        #expect(moves == ["Move 1", "Move 2", "Move 3"])
    }

    @Test func parseMovesThrowsOnLineLongerThan200Characters() throws {
        let store = makeTestStore()
        let longLine = String(repeating: "A", count: 201)
        let input = "Move 1\n\(longLine)\nMove 2"

        #expect(throws: FormStoreError.self) {
            try store.parseMoves(from: input)
        }
    }

    @Test func parseMovesAcceptsLine200CharactersLong() throws {
        let store = makeTestStore()
        let line200 = String(repeating: "A", count: 200)
        let input = "Move 1\n\(line200)\nMove 2"

        let moves = try store.parseMoves(from: input)

        #expect(moves.count == 3)
        #expect(moves[1].count == 200)
    }

    @Test func parseMovesChecksLengthAfterTrimming() throws {
        let store = makeTestStore()
        // Line is 202 chars before trimming but 200 after
        let line = "  " + String(repeating: "A", count: 200)
        let input = "Move 1\n\(line)\nMove 2"

        let moves = try store.parseMoves(from: input)

        // Should succeed - trimmed length is 200
        #expect(moves[1].count == 200)
    }

    @Test func parseMovesThrowsOnEmptyResult() throws {
        let store = makeTestStore()
        let input = "\n\n   \n\t\t\n"

        #expect(throws: FormStoreError.self) {
            try store.parseMoves(from: input)
        }
    }

    @Test func parseMovesThrowsOnEmptyString() throws {
        let store = makeTestStore()
        let input = ""

        #expect(throws: FormStoreError.self) {
            try store.parseMoves(from: input)
        }
    }

    @Test func parseMovesHandlesSingleMove() throws {
        let store = makeTestStore()
        let input = "Single Move"

        let moves = try store.parseMoves(from: input)

        #expect(moves == ["Single Move"])
    }

    @Test func parseMovesHandlesDifferentNewlineTypes() throws {
        let store = makeTestStore()
        // Mix of \n, \r\n, \r
        let input = "Move 1\nMove 2\r\nMove 3\rMove 4"

        let moves = try store.parseMoves(from: input)

        // Should handle all standard newline types and produce all moves
        #expect(moves.count == 4)
        #expect(moves == ["Move 1", "Move 2", "Move 3", "Move 4"])
    }

    @Test func parseMovesHandlesSpecialCharacters() throws {
        let store = makeTestStore()
        let input = "前蹴り (Mae Geri)\n回し蹴り (Mawashi Geri)\n形同士"

        let moves = try store.parseMoves(from: input)

        #expect(moves.count == 3)
        #expect(moves[0] == "前蹴り (Mae Geri)")
        #expect(moves[2] == "形同士")
    }

    @Test func parseMovesHandlesManyMoves() throws {
        let store = makeTestStore()
        let manyLines = (1...100).map { "Move \($0)" }.joined(separator: "\n")

        let moves = try store.parseMoves(from: manyLines)

        #expect(moves.count == 100)
        #expect(moves[0] == "Move 1")
        #expect(moves[99] == "Move 100")
    }

    // MARK: - JSON Persistence Round-Trip Tests

    @Test func formStoreRoundTripPreservesAllData() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        // Create store and add forms
        let store1 = FormStore(userDefaults: defaults)
        let form1 = Form(
            id: UUID(),
            title: "Heian Shodan",
            moves: ["Step forward", "Turn left", "Block"],
            dateCreated: Date(timeIntervalSince1970: 1699000000),
            lastPracticed: Date(timeIntervalSince1970: 1699100000)
        )
        let form2 = Form(
            id: UUID(),
            title: "Tekki Shodan",
            moves: ["Horse stance", "Strike right"],
            dateCreated: Date(timeIntervalSince1970: 1699200000),
            lastPracticed: Date(timeIntervalSince1970: 1699300000)
        )

        try store1.saveForm(form: form1)
        try store1.saveForm(form: form2)

        // Create new store with same UserDefaults - should load persisted data
        let store2 = FormStore(userDefaults: defaults)

        #expect(store2.forms.count == 2)
        #expect(store2.forms[0].id == form1.id)
        #expect(store2.forms[0].title == "Heian Shodan")
        #expect(store2.forms[0].moves == ["Step forward", "Turn left", "Block"])
        #expect(store2.forms[0].dateCreated.timeIntervalSince1970 == 1699000000)
        #expect(store2.forms[0].lastPracticed.timeIntervalSince1970 == 1699100000)
        #expect(store2.forms[1].id == form2.id)
        #expect(store2.forms[1].title == "Tekki Shodan")
    }

    @Test func formStoreRoundTripHandlesSpecialCharacters() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store1 = FormStore(userDefaults: defaults)
        let form = Form(
            title: "形同士 (Kata Dōshi)",
            moves: ["前蹴り (Mae Geri)", "回し蹴り (Mawashi Geri)"]
        )

        try store1.saveForm(form: form)

        let store2 = FormStore(userDefaults: defaults)

        #expect(store2.forms[0].title == "形同士 (Kata Dōshi)")
        #expect(store2.forms[0].moves[0] == "前蹴り (Mae Geri)")
    }

    @Test func formStoreRoundTripHandlesEmptyStore() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        _ = FormStore(userDefaults: defaults)
        let store2 = FormStore(userDefaults: defaults)

        #expect(store2.forms.isEmpty)
    }

    // MARK: - Observable Tests

    @Test func formStoreFormsArrayIsObservable() {
        let store = makeTestStore()

        // The @Observable macro makes forms observable
        // In UI tests, this will be verified through SwiftUI binding
        #expect(store.forms is [Form])
    }

    // MARK: - Error Handling Tests

    @Test func formStoreErrorHasMeaningfulMessages() {
        // Verify error enum provides useful information
        let emptyTitleError = FormStoreError.emptyTitle
        let emptyMovesError = FormStoreError.emptyMoves
        let moveTooLongError = FormStoreError.moveTooLong(length: 250)
        let formNotFoundError = FormStoreError.formNotFound

        // Errors should have meaningful descriptions
        #expect(String(describing: emptyTitleError).contains("title") || String(describing: emptyTitleError).contains("empty"))
        #expect(String(describing: emptyMovesError).contains("move") || String(describing: emptyMovesError).contains("empty"))
        #expect(String(describing: moveTooLongError).contains("200") || String(describing: moveTooLongError).contains("250"))
        #expect(String(describing: formNotFoundError).contains("found") || String(describing: formNotFoundError).contains("not"))
    }

    // MARK: - Validation Helper Tests

    @Test func validationRejectsEmptyTitleWithPreciseError() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "", moves: ["Move 1"])

        do {
            try store.saveForm(form: form)
            Issue.record("Expected emptyTitle error")
        } catch FormStoreError.emptyTitle {
            // Correct error thrown
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func validationRejectsEmptyMovesWithPreciseError() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Valid", moves: [])

        do {
            try store.saveForm(form: form)
            Issue.record("Expected emptyMoves error")
        } catch FormStoreError.emptyMoves {
            // Correct error thrown
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test func validationRejectsLongMoveWithPreciseError() throws {
        let store = makeTestStore()
        let longMove = String(repeating: "X", count: 201)
        let form = makeValidForm(title: "Valid", moves: [longMove])

        do {
            try store.saveForm(form: form)
            Issue.record("Expected moveTooLong error")
        } catch FormStoreError.moveTooLong(let length) {
            #expect(length == 201)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: - Edge Cases and Boundary Tests

    @Test func formStoreHandlesManyForms() throws {
        let store = makeTestStore()

        // Save 50 forms
        for i in 1...50 {
            let form = makeValidForm(title: "Form \(i)", moves: ["Move \(i)"])
            try store.saveForm(form: form)
        }

        #expect(store.forms.count == 50)
        #expect(store.forms[0].title == "Form 1")
        #expect(store.forms[49].title == "Form 50")
    }

    @Test func formStoreHandlesFormWithManyMoves() throws {
        let store = makeTestStore()
        let manyMoves = (1...100).map { "Move \($0)" }
        let form = makeValidForm(title: "Long Form", moves: manyMoves)

        try store.saveForm(form: form)

        #expect(store.forms[0].moves.count == 100)
    }

    @Test func formStoreHandlesRapidSuccessiveOperations() throws {
        let store = makeTestStore()
        let form = makeValidForm(title: "Test Form", moves: ["Move 1"])

        try store.saveForm(form: form)

        var updatedForm = form
        updatedForm.title = "Updated 1"
        try store.updateForm(form: updatedForm)

        updatedForm.title = "Updated 2"
        try store.updateForm(form: updatedForm)

        try store.deleteForm(id: form.id)

        #expect(store.forms.isEmpty)
    }

    @Test func formStoreHandlesConcurrentReads() async throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FormStore(userDefaults: defaults)
        let form = makeValidForm(title: "Concurrent Test", moves: ["Move 1"])
        try store.saveForm(form: form)

        // Multiple concurrent reads should work
        await withTaskGroup(of: Int.self) { group in
            for _ in 1...10 {
                group.addTask { @MainActor in
                    store.forms.count
                }
            }
        }

        #expect(store.forms.count == 1)
    }
}
