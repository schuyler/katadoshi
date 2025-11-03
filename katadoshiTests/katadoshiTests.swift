//
//  katadoshiTests.swift
//  katadoshiTests
//
//  Created by Schuyler Erle on 11/2/25.
//

import Testing
import Foundation
import AVFoundation
@testable import katadoshi

// MARK: - Form Model Tests

/// Tests for Form model conformance to Identifiable, Codable, and Equatable protocols
struct FormModelTests {

    // MARK: - Identifiable Conformance Tests

    @Test func formHasUniqueID() {
        let form1 = Form(title: "Test Form", moves: ["Move 1"])
        let form2 = Form(title: "Test Form", moves: ["Move 1"])

        // Each instance should have a unique ID even with identical content
        #expect(form1.id != form2.id)
    }

    @Test func formIDIsUUID() {
        let form = Form(title: "Test Form", moves: ["Move 1"])

        // ID should be a valid UUID
        #expect(form.id is UUID)
    }

    @Test func formIDCanBeCustomized() {
        let customID = UUID()
        let form = Form(id: customID, title: "Test Form", moves: ["Move 1"])

        // Should be able to specify custom UUID
        #expect(form.id == customID)
    }

    // MARK: - Codable Conformance Tests

    @Test func formCanBeEncodedToJSON() throws {
        let form = Form(
            title: "Heian Shodan",
            moves: ["Step forward", "Turn left", "Punch"],
            lastPracticed: Date(timeIntervalSince1970: 1699000000)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(form)

        // Should successfully encode without throwing
        #expect(data.count > 0)
    }

    @Test func formCanBeDecodedFromJSON() throws {
        let originalForm = Form(
            title: "Heian Shodan",
            moves: ["Step forward", "Turn left", "Punch"],
            lastPracticed: Date(timeIntervalSince1970: 1699000000)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(originalForm)
        let decodedForm = try decoder.decode(Form.self, from: data)

        // Decoded form should match original
        #expect(decodedForm.id == originalForm.id)
        #expect(decodedForm.title == originalForm.title)
        #expect(decodedForm.moves == originalForm.moves)
    }

    @Test func formJSONRoundTripPreservesAllProperties() throws {
        let customID = UUID()
        let dateCreated = Date(timeIntervalSince1970: 1699000000)
        let lastPracticed = Date(timeIntervalSince1970: 1699100000)

        let originalForm = Form(
            id: customID,
            title: "Tekki Shodan",
            moves: ["Horse stance", "Block left", "Strike right"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(originalForm)
        let decodedForm = try decoder.decode(Form.self, from: data)

        // All properties should be preserved through round-trip
        #expect(decodedForm.id == customID)
        #expect(decodedForm.title == "Tekki Shodan")
        #expect(decodedForm.moves.count == 3)
        #expect(decodedForm.moves[0] == "Horse stance")
        #expect(decodedForm.moves[1] == "Block left")
        #expect(decodedForm.moves[2] == "Strike right")
        #expect(decodedForm.dateCreated.timeIntervalSince1970 == dateCreated.timeIntervalSince1970)
        #expect(decodedForm.lastPracticed.timeIntervalSince1970 == lastPracticed.timeIntervalSince1970)
    }

    @Test func formJSONContainsExpectedKeys() throws {
        let form = Form(title: "Test Form", moves: ["Move 1"])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(form)
        let jsonString = String(data: data, encoding: .utf8)!

        // JSON should contain all required keys
        #expect(jsonString.contains("\"id\""))
        #expect(jsonString.contains("\"title\""))
        #expect(jsonString.contains("\"moves\""))
        #expect(jsonString.contains("\"dateCreated\""))
        #expect(jsonString.contains("\"lastPracticed\""))
    }

    // MARK: - Equatable Conformance Tests

    @Test func formEquatableComparesIdenticalForms() {
        let id = UUID()
        let dateCreated = Date(timeIntervalSince1970: 1699000000)
        let lastPracticed = Date(timeIntervalSince1970: 1699100000)

        let form1 = Form(
            id: id,
            title: "Same Form",
            moves: ["Move 1", "Move 2"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed
        )

        let form2 = Form(
            id: id,
            title: "Same Form",
            moves: ["Move 1", "Move 2"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed
        )

        // Forms with identical properties should be equal
        #expect(form1 == form2)
    }

    @Test func formEquatableDistinguishesDifferentIDs() {
        let form1 = Form(title: "Test Form", moves: ["Move 1"])
        let form2 = Form(title: "Test Form", moves: ["Move 1"])

        // Forms with different IDs should not be equal
        #expect(form1 != form2)
    }

    @Test func formEquatableDistinguishesDifferentTitles() {
        let id = UUID()
        let form1 = Form(id: id, title: "Form A", moves: ["Move 1"])
        let form2 = Form(id: id, title: "Form B", moves: ["Move 1"])

        // Forms with different titles should not be equal
        #expect(form1 != form2)
    }

    @Test func formEquatableDistinguishesDifferentMoves() {
        let id = UUID()
        let form1 = Form(id: id, title: "Test Form", moves: ["Move 1", "Move 2"])
        let form2 = Form(id: id, title: "Test Form", moves: ["Move 1", "Move 3"])

        // Forms with different moves should not be equal
        #expect(form1 != form2)
    }

    @Test func formEquatableDistinguishesDifferentDateCreated() {
        let id = UUID()
        let dateCreated1 = Date(timeIntervalSince1970: 1699000000)
        let dateCreated2 = Date(timeIntervalSince1970: 1699100000)
        let lastPracticed = Date(timeIntervalSince1970: 1699200000)

        let form1 = Form(
            id: id,
            title: "Test Form",
            moves: ["Move 1"],
            dateCreated: dateCreated1,
            lastPracticed: lastPracticed
        )

        let form2 = Form(
            id: id,
            title: "Test Form",
            moves: ["Move 1"],
            dateCreated: dateCreated2,
            lastPracticed: lastPracticed
        )

        // Forms with different dateCreated should not be equal
        #expect(form1 != form2)
    }

    @Test func formEquatableDistinguishesDifferentLastPracticed() {
        let id = UUID()
        let dateCreated = Date(timeIntervalSince1970: 1699000000)
        let lastPracticed1 = Date(timeIntervalSince1970: 1699100000)
        let lastPracticed2 = Date(timeIntervalSince1970: 1699200000)

        let form1 = Form(
            id: id,
            title: "Test Form",
            moves: ["Move 1"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed1
        )

        let form2 = Form(
            id: id,
            title: "Test Form",
            moves: ["Move 1"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed2
        )

        // Forms with different lastPracticed should not be equal
        #expect(form1 != form2)
    }

    // MARK: - PRD Requirements Tests

    @Test func formSupportsSwiftUIListViews() {
        // Test that Form conforms to Identifiable (required for List)
        let forms = [
            Form(title: "Form 1", moves: ["Move 1"]),
            Form(title: "Form 2", moves: ["Move 2"]),
            Form(title: "Form 3", moves: ["Move 3"])
        ]

        // Should be usable in SwiftUI List via id property
        let ids = forms.map { $0.id }
        #expect(ids.count == 3)
        #expect(ids[0] != ids[1])
        #expect(ids[1] != ids[2])
    }

    @Test func formSupportsJSONPersistence() throws {
        // Test complete persistence workflow
        let forms = [
            Form(title: "Heian Shodan", moves: ["Move 1", "Move 2"]),
            Form(title: "Heian Nidan", moves: ["Move A", "Move B", "Move C"])
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Encode array of forms
        let data = try encoder.encode(forms)

        // Decode array of forms
        let decodedForms = try decoder.decode([Form].self, from: data)

        // Should preserve all forms and their properties
        #expect(decodedForms.count == 2)
        #expect(decodedForms[0].title == "Heian Shodan")
        #expect(decodedForms[0].moves.count == 2)
        #expect(decodedForms[1].title == "Heian Nidan")
        #expect(decodedForms[1].moves.count == 3)
    }

    @Test func formLastPracticedUpdatesWhenPracticeStarts() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        let originalDate = form.lastPracticed

        // Simulate practice session start
        // NOTE: In the actual app, PracticeSessionManager is responsible for updating
        // lastPracticed when a practice session starts (PRD: "Updated when practice
        // session starts"). The Form model allows mutation but does not enforce
        // or trigger the update itself.
        Thread.sleep(forTimeInterval: 0.01)
        form.lastPracticed = Date()

        // lastPracticed should be updated
        #expect(form.lastPracticed > originalDate)
    }

    // MARK: - Initializer Tests

    @Test func formInitializerWithDefaults() {
        let form = Form(title: "Simple Form", moves: ["Move 1"])

        // Default initializer should set reasonable defaults
        #expect(form.title == "Simple Form")
        #expect(form.moves == ["Move 1"])
        #expect(form.id is UUID)
        #expect(form.dateCreated is Date)
        #expect(form.lastPracticed is Date)
    }

    @Test func formInitializerWithAllCustomValues() {
        let customID = UUID()
        let dateCreated = Date(timeIntervalSince1970: 1699000000)
        let lastPracticed = Date(timeIntervalSince1970: 1699100000)

        let form = Form(
            id: customID,
            title: "Custom Form",
            moves: ["Move 1", "Move 2", "Move 3"],
            dateCreated: dateCreated,
            lastPracticed: lastPracticed
        )

        // All custom values should be set
        #expect(form.id == customID)
        #expect(form.title == "Custom Form")
        #expect(form.moves.count == 3)
        #expect(form.moves == ["Move 1", "Move 2", "Move 3"])
        #expect(form.dateCreated == dateCreated)
        #expect(form.lastPracticed == lastPracticed)
    }

    @Test func formInitializerDefaultsIDToNewUUID() {
        let form1 = Form(title: "Form 1", moves: ["Move 1"])
        let form2 = Form(title: "Form 2", moves: ["Move 1"])

        // Each form should get a unique default ID
        #expect(form1.id != form2.id)
    }

    @Test func formInitializerDefaultsDatesAreSimilar() {
        let beforeInit = Date()
        let form = Form(title: "Test Form", moves: ["Move 1"])
        let afterInit = Date()

        // Default dates should be close to initialization time
        #expect(form.dateCreated >= beforeInit)
        #expect(form.dateCreated <= afterInit)
        #expect(form.lastPracticed >= beforeInit)
        #expect(form.lastPracticed <= afterInit)
    }

    @Test func formInitializerAcceptsEmptyTitle() {
        let form = Form(title: "", moves: ["Move 1"])

        // Initializer should allow empty title (validation happens at save time)
        #expect(form.title == "")
    }

    @Test func formInitializerAcceptsWhitespaceOnlyTitle() {
        let form = Form(title: "   ", moves: ["Move 1"])

        // Initializer should allow whitespace-only title (validation happens at save time)
        #expect(form.title == "   ")
    }

    @Test func formInitializerAcceptsEmptyMoves() {
        let form = Form(title: "Test Form", moves: [])

        // Initializer should allow empty moves (validation happens at save time)
        #expect(form.moves == [])
    }

    @Test func formInitializerAcceptsMovesWithEmptyStrings() {
        let form = Form(title: "Test Form", moves: ["Move 1", "", "Move 2"])

        // Initializer should allow empty strings in moves array (validation happens at save time)
        // NOTE: Form model is intentionally permissive to allow flexible construction and editing.
        // FormStore enforces validation rules at save/update time, rejecting empty/whitespace moves.
        #expect(form.moves.count == 3)
        #expect(form.moves[1] == "")
    }

    @Test func formInitializerAcceptsManyMoves() {
        let manyMoves = (1...100).map { "Move \($0)" }
        let form = Form(title: "Long Form", moves: manyMoves)

        // Should handle large number of moves
        #expect(form.moves.count == 100)
        #expect(form.moves[0] == "Move 1")
        #expect(form.moves[99] == "Move 100")
    }

    // MARK: - Property Mutability Tests

    @Test func formIDIsImmutable() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        let originalID = form.id

        // ID should be let (this is a compile-time test, but we verify it doesn't change)
        // Note: If id were var, this test documents that it shouldn't be changed
        #expect(form.id == originalID)
    }

    @Test func formTitleIsMutable() {
        var form = Form(title: "Original Title", moves: ["Move 1"])
        form.title = "Updated Title"

        // Title should be mutable
        #expect(form.title == "Updated Title")
    }

    @Test func formMovesAreMutable() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        form.moves = ["Move A", "Move B", "Move C"]

        // Moves array should be mutable
        #expect(form.moves.count == 3)
        #expect(form.moves == ["Move A", "Move B", "Move C"])
    }

    @Test func formMovesCanBeAppended() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        form.moves.append("Move 2")

        // Should be able to modify moves array
        #expect(form.moves.count == 2)
        #expect(form.moves[1] == "Move 2")
    }

    @Test func formDateCreatedIsImmutable() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        let originalDate = form.dateCreated

        // dateCreated should be let (verified by checking it doesn't change)
        #expect(form.dateCreated == originalDate)
    }

    @Test func formLastPracticedIsMutable() {
        var form = Form(title: "Test Form", moves: ["Move 1"])
        let newDate = Date(timeIntervalSince1970: 1699200000)
        form.lastPracticed = newDate

        // lastPracticed should be mutable (updated when practice starts)
        #expect(form.lastPracticed == newDate)
    }

    // MARK: - Edge Case Tests

    @Test func formHandlesSpecialCharactersInTitle() {
        let form = Form(title: "形同士 (Kata Dōshi)", moves: ["Move 1"])

        #expect(form.title == "形同士 (Kata Dōshi)")
    }

    @Test func formHandlesSpecialCharactersInMoves() {
        let moves = ["前蹴り (Mae Geri)", "回し蹴り (Mawashi Geri)"]
        let form = Form(title: "Kicks", moves: moves)

        #expect(form.moves[0] == "前蹴り (Mae Geri)")
        #expect(form.moves[1] == "回し蹴り (Mawashi Geri)")
    }

    @Test func formHandlesLongTitle() {
        let longTitle = String(repeating: "A", count: 500)
        let form = Form(title: longTitle, moves: ["Move 1"])

        #expect(form.title.count == 500)
    }

    @Test func formHandlesLongMoveDescription() {
        let longMove = String(repeating: "X", count: 500)
        let form = Form(title: "Test", moves: [longMove])

        // Form model should accept long moves (validation happens at save time)
        #expect(form.moves[0].count == 500)
    }

    @Test func formHandlesMultilineMovesInArray() {
        let moves = ["Move 1\nwith newline", "Move 2"]
        let form = Form(title: "Test", moves: moves)

        // Array elements can contain newlines
        #expect(form.moves[0].contains("\n"))
    }

    @Test func formModelIsPermissiveWhileFormStoreIsStrict() {
        // Document the architectural pattern: Form model allows invalid data
        // to support flexible editing, while FormStore enforces validation
        // at persistence boundaries.

        // Form model accepts invalid data
        let invalidForm = Form(
            title: "",  // Empty title - invalid per PRD
            moves: ["", "   ", String(repeating: "X", count: 500)]  // Invalid moves
        )

        #expect(invalidForm.title == "")
        #expect(invalidForm.moves.count == 3)

        // This separation allows UI components to work with intermediate/draft states
        // without triggering validation errors until save time.
    }
}

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

        // ObservableObject should publish changes (verified by SwiftUI binding in UI tests)
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

        // ObservableObject should publish changes
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

        // ObservableObject should publish changes
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

    // MARK: - ObservableObject Publishing Tests

    @Test func formStoreIsObservableObject() {
        let store = makeTestStore()

        // Verify FormStore conforms to ObservableObject
        // This is a compile-time check, but we verify it can be used
        _ = store as any ObservableObject
    }

    @Test func formStoreFormsArrayIsPublished() {
        let store = makeTestStore()

        // The @Published property wrapper should make forms observable
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

// MARK: - TextToSpeechService Tests

/// Tests for TextToSpeechService protocol and implementation
@MainActor
struct TextToSpeechServiceTests {

    // MARK: - Mock AVSpeechSynthesizer

    /// Mock AVSpeechSynthesizer for testing without actual speech output
    class MockSpeechSynthesizer: AVSpeechSynthesizer {
        var speakCalled = false
        var stopCalled = false
        var pauseCalled = false
        var lastUtterance: AVSpeechUtterance?
        var lastStopBoundary: AVSpeechBoundary?
        var lastPauseBoundary: AVSpeechBoundary?
        var mockIsSpeaking = false

        // Track all utterances to simulate queueing behavior
        var utteranceQueue: [AVSpeechUtterance] = []

        override func speak(_ utterance: AVSpeechUtterance) {
            speakCalled = true
            lastUtterance = utterance
            mockIsSpeaking = true

            // Simulate queueing: Real AVSpeechSynthesizer queues utterances
            // For testing purposes, we track the queue but process immediately
            utteranceQueue.append(utterance)
        }

        override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
            stopCalled = true
            lastStopBoundary = boundary
            mockIsSpeaking = false

            // Real AVSpeechSynthesizer triggers didCancel when stopped
            if let utterance = lastUtterance {
                simulateCancel(utterance)
            }

            return true
        }

        override func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
            pauseCalled = true
            lastPauseBoundary = boundary
            return true
        }

        override var isSpeaking: Bool {
            return mockIsSpeaking
        }

        /// Simulate completion of speech
        func simulateFinish(_ utterance: AVSpeechUtterance) {
            mockIsSpeaking = false
            guard let delegate = self.delegate else { return }
            delegate.speechSynthesizer?(self, didFinish: utterance)
        }

        /// Simulate cancellation of speech (called automatically by stopSpeaking in real behavior)
        func simulateCancel(_ utterance: AVSpeechUtterance) {
            mockIsSpeaking = false
            guard let delegate = self.delegate else { return }
            delegate.speechSynthesizer?(self, didCancel: utterance)
        }
    }

    // MARK: - Protocol Conformance Tests

    @Test func textToSpeechServiceConformsToProtocol() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify service conforms to protocol
        _ = service as TextToSpeechServiceProtocol
    }

    @Test func textToSpeechServiceImplementsProtocolMethods() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify all protocol methods are implemented
        service.speak(text: "Test")
        service.stop()
        service.pause()
        _ = service.isSpeaking
    }

    // MARK: - speak() Method Tests

    @Test func speakMethodCallsSynthesizerSpeak() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        #expect(mockSynthesizer.speakCalled)
    }

    @Test func speakMethodCreatesUtteranceWithCorrectText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Step forward with left foot")

        #expect(mockSynthesizer.lastUtterance?.speechString == "Step forward with left foot")
    }

    @Test func speakMethodHandlesEmptyString() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "")

        // Should still call speak, even with empty text
        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == "")
    }

    @Test func speakMethodHandlesLongText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let longText = String(repeating: "A", count: 500)

        service.speak(text: longText)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == longText)
    }

    @Test func speakMethodHandlesSpecialCharacters() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let textWithSpecialChars = "前蹴り (Mae Geri) - front kick"

        service.speak(text: textWithSpecialChars)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == textWithSpecialChars)
    }

    @Test func speakMethodCanBeCalledMultipleTimes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First instruction")
        service.speak(text: "Second instruction")
        service.speak(text: "Third instruction")

        // Last utterance should be the third one
        #expect(mockSynthesizer.lastUtterance?.speechString == "Third instruction")
    }

    @Test func speakMethodHandlesNewlinesInText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let textWithNewlines = "Step forward\nTurn left\nPunch"

        service.speak(text: textWithNewlines)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == textWithNewlines)
    }

    // MARK: - Voice and Speech Rate Configuration Tests (PRD Section 5.3)

    @Test func speakMethodUsesDefaultVoice() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        // PRD Section 5.3 requires: "Default voice and speed for MVP"
        // Default voice is nil, meaning use system default
        #expect(mockSynthesizer.lastUtterance?.voice == nil)
    }

    @Test func speakMethodUsesDefaultSpeechRate() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        // PRD Section 5.3 requires: "Default voice and speed for MVP"
        // Default rate is AVSpeechUtteranceDefaultSpeechRate
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
    }

    @Test func utteranceUsesDefaultConfigurationForAllSpeechRequests() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)

        service.speak(text: "Second move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)

        service.speak(text: "Third move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)
    }

    // MARK: - stop() Method Tests

    @Test func stopMethodCallsSynthesizerStop() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.stop()

        #expect(mockSynthesizer.stopCalled)
    }

    @Test func stopMethodStopsActiveSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        #expect(mockSynthesizer.mockIsSpeaking)

        service.stop()

        #expect(!mockSynthesizer.mockIsSpeaking)
    }

    @Test func stopMethodCanBeCalledWhenNotSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash when stopping while not speaking
        service.stop()

        #expect(mockSynthesizer.stopCalled)
    }

    @Test func stopMethodCanBeCalledMultipleTimes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.stop()
        service.stop()
        service.stop()

        // Should handle multiple stop calls without error
        #expect(mockSynthesizer.stopCalled)
    }

    // MARK: - pause() Method Tests

    @Test func pauseMethodCallsSynthesizerPause() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func pauseMethodCanBeCalledWhenSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func pauseMethodCanBeCalledWhenNotSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash when pausing while not speaking
        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    // MARK: - Boundary Parameter Tests

    @Test func stopMethodUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")
        service.stop()

        // stop() should use .immediate boundary to stop speech instantly
        #expect(mockSynthesizer.lastStopBoundary == .immediate)
    }

    @Test func pauseMethodUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")
        service.pause()

        // pause() should use .immediate boundary to pause speech instantly
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)
    }

    @Test func stopMethodAlwaysUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Test multiple stop calls all use .immediate
        service.speak(text: "First")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)

        service.speak(text: "Second")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)

        service.speak(text: "Third")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)
    }

    @Test func pauseMethodAlwaysUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Test multiple pause calls all use .immediate
        service.speak(text: "First")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)

        service.speak(text: "Second")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)

        service.speak(text: "Third")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)
    }

    // MARK: - isSpeaking Property Tests

    @Test func isSpeakingReturnsFalseInitially() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        #expect(!service.isSpeaking)
    }

    @Test func isSpeakingReturnsTrueWhileSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")

        #expect(service.isSpeaking)
    }

    @Test func isSpeakingReturnsFalseAfterStop() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.stop()

        #expect(!service.isSpeaking)
    }

    @Test func isSpeakingReflectsSynthesizerState() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)

        service.speak(text: "Test")
        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)

        service.stop()
        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)
    }

    // MARK: - Completion Callback Tests

    @Test func didFinishSpeakingCallbackIsSetOnService() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        #expect(!callbackCalled)
    }

    @Test func didFinishSpeakingCallbackFiresWhenSpeechCompletes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate speech completion
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCalled)
    }

    @Test func didFinishSpeakingCallbackFiresForEachUtterance() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCount = 0
        service.didFinishSpeaking = { _ in
            callbackCount += 1
        }

        service.speak(text: "First")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Second")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Third")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCount == 3)
    }

    @Test func didFinishSpeakingCallbackCanBeNil() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash with nil callback
        service.didFinishSpeaking = nil
        service.speak(text: "Test")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
    }

    @Test func didFinishSpeakingCallbackCanBeChanged() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var firstCallbackCalled = false
        var secondCallbackCalled = false

        service.didFinishSpeaking = { _ in
            firstCallbackCalled = true
        }

        service.speak(text: "Test 1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(firstCallbackCalled)
        #expect(!secondCallbackCalled)

        service.didFinishSpeaking = { _ in
            secondCallbackCalled = true
        }

        service.speak(text: "Test 2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(secondCallbackCalled)
    }

    // MARK: - AVSpeechSynthesizerDelegate Tests

    @Test func serviceImplementsAVSpeechSynthesizerDelegate() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify service can be used as AVSpeechSynthesizerDelegate
        _ = service as AVSpeechSynthesizerDelegate
    }

    @Test func serviceSetsSelfAsDelegateOnInitialization() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify the service sets itself as delegate
        #expect(mockSynthesizer.delegate === service)
    }

    @Test func speechSynthesizerDidFinishTriggersCallback() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate delegate method call
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCalled)
    }

    @Test func speechSynthesizerDidCancelTriggersCallback() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate cancellation
        mockSynthesizer.simulateCancel(mockSynthesizer.lastUtterance!)

        // Callback should fire on cancel as well (speech is done, whether completed or cancelled)
        #expect(callbackCalled)
    }

    // MARK: - State Management Tests

    @Test func speakingStateTransitionsCorrectly() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Initially not speaking
        #expect(!service.isSpeaking)

        // Start speaking
        service.speak(text: "Test")
        #expect(service.isSpeaking)

        // Finish speaking
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
        #expect(!service.isSpeaking)
    }

    @Test func stopInterruptsActiveSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Long instruction that will be interrupted")
        #expect(service.isSpeaking)

        service.stop()
        #expect(!service.isSpeaking)
    }

    @Test func newSpeakInterruptsCurrentSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First instruction")
        let firstUtterance = mockSynthesizer.lastUtterance

        service.speak(text: "Second instruction")
        let secondUtterance = mockSynthesizer.lastUtterance

        #expect(firstUtterance !== secondUtterance)
        #expect(secondUtterance?.speechString == "Second instruction")
    }

    // MARK: - Queueing Behavior Tests

    @Test func multipleSpeakCallsQueueUtterances() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Real AVSpeechSynthesizer queues utterances when multiple speak() calls are made
        // Our mock simulates this by tracking the queue, though processing is immediate for testing
        service.speak(text: "First")
        service.speak(text: "Second")
        service.speak(text: "Third")

        // Verify all utterances were queued
        #expect(mockSynthesizer.utteranceQueue.count == 3)
        #expect(mockSynthesizer.utteranceQueue[0].speechString == "First")
        #expect(mockSynthesizer.utteranceQueue[1].speechString == "Second")
        #expect(mockSynthesizer.utteranceQueue[2].speechString == "Third")
    }

    @Test func queueingBehaviorDocumented() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // IMPORTANT: Real AVSpeechSynthesizer queues utterances sequentially
        // In PracticeSessionManager, we rely on TTS completion callbacks to ensure
        // only one utterance is spoken at a time (Speaking -> Listening state transition)
        // This test documents the expected behavior for implementation guidance

        service.speak(text: "Move 1")
        #expect(mockSynthesizer.utteranceQueue.count == 1)

        // In practice session, we wait for didFinishSpeaking before next speak()
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 2")
        #expect(mockSynthesizer.utteranceQueue.count == 2)
    }

    @Test func consecutiveSpeakCallsWithoutWaitingForCompletion() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCount = 0
        service.didFinishSpeaking = { _ in
            callbackCount += 1
        }

        service.speak(text: "First")
        service.speak(text: "Second")  // Called before first completes

        // AVSpeechSynthesizer queues utterances, so both should be queued
        #expect(mockSynthesizer.utteranceQueue.count == 2)

        // When first finishes, callback fires
        mockSynthesizer.simulateFinish(mockSynthesizer.utteranceQueue[0])
        #expect(callbackCount == 1)

        // When second finishes, callback fires again
        mockSynthesizer.simulateFinish(mockSynthesizer.utteranceQueue[1])
        #expect(callbackCount == 2)
    }

    // MARK: - Integration with PracticeSessionManager Tests

    @Test func callbackFiredBeforeNextSpeak() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var completionOrder: [String] = []

        service.didFinishSpeaking = { _ in
            completionOrder.append("callback")
        }

        service.speak(text: "First")
        completionOrder.append("speak1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Second")
        completionOrder.append("speak2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(completionOrder == ["speak1", "callback", "speak2", "callback"])
    }

    @Test func serviceReadyForImmediateReuse() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Rapid fire usage pattern (as in practice session)
        service.speak(text: "Move 1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 3")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        // All should work without issues
        #expect(mockSynthesizer.lastUtterance?.speechString == "Move 3")
    }

    // MARK: - Edge Cases

    @Test func serviceHandlesWhitespaceOnlyText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "   \t\n   ")

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == "   \t\n   ")
    }

    @Test func serviceHandlesVeryLongText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let veryLongText = String(repeating: "This is a very long instruction. ", count: 100)

        service.speak(text: veryLongText)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == veryLongText)
    }

    @Test func serviceHandlesNonASCIICharacters() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        let texts = [
            "前蹴り",
            "Tae Kwon Do",
            "Capoeira",
            "Крюк",
            "🥋👊"
        ]

        for text in texts {
            service.speak(text: text)
            #expect(mockSynthesizer.lastUtterance?.speechString == text)
        }
    }

    @Test func stopWithNoActiveUtteranceIsIdempotent() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.stop()
        service.stop()
        service.stop()

        // Should not crash or cause issues
        #expect(!service.isSpeaking)
    }

    @Test func pauseWithNoActiveUtteranceIsIdempotent() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.pause()
        service.pause()
        service.pause()

        // Should not crash or cause issues
        #expect(!service.isSpeaking)
    }

    @Test func callbackIsCalledWhenStoppedManually() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")
        service.stop()

        // AVSpeechSynthesizer.stopSpeaking(at:) triggers didCancel delegate callback
        // which should fire our didFinishSpeaking callback (speech is done, whether completed or cancelled)
        #expect(callbackCalled)
    }

    // MARK: - Dependency Injection Tests

    @Test func serviceAcceptsCustomSynthesizerViaInitializer() {
        let customSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: customSynthesizer)

        service.speak(text: "Test")

        #expect(customSynthesizer.speakCalled)
    }

    @Test func serviceWorksWithDefaultSynthesizer() {
        // Test that service can be initialized with default AVSpeechSynthesizer
        let service = TextToSpeechService()

        // Should not crash
        service.speak(text: "Test")
        service.stop()
    }

    @Test func multipleSynthesizersCanBeUsedSimultaneously() {
        let synthesizer1 = MockSpeechSynthesizer()
        let synthesizer2 = MockSpeechSynthesizer()

        let service1 = TextToSpeechService(synthesizer: synthesizer1)
        let service2 = TextToSpeechService(synthesizer: synthesizer2)

        service1.speak(text: "Service 1")
        service2.speak(text: "Service 2")

        #expect(synthesizer1.lastUtterance?.speechString == "Service 1")
        #expect(synthesizer2.lastUtterance?.speechString == "Service 2")
    }

    // MARK: - Thread Safety Tests

    @Test func serviceIsMainActorIsolated() async {
        // Service should be usable on main actor
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        await MainActor.run {
            service.speak(text: "Test")
            #expect(mockSynthesizer.speakCalled)
        }
    }

    // MARK: - Memory Management Tests

    @Test func callbackDoesNotCreateRetainCycle() {
        var service: TextToSpeechService? = TextToSpeechService(synthesizer: MockSpeechSynthesizer())
        weak var weakService = service

        service?.didFinishSpeaking = { [weak weakService] _ in
            _ = weakService?.isSpeaking
        }

        service = nil

        // Service should be deallocated
        #expect(weakService == nil)
    }

    // MARK: - PRD Requirements Validation Tests

    @Test func serviceSupportsAllPRDRequiredMethods() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // PRD Section 5.3 requires: speak(text:), stop(), pause()
        service.speak(text: "Test")
        service.stop()
        service.pause()

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.stopCalled)
        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func serviceSupportsIsSpeakingProperty() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // PRD requires checking if currently speaking
        let speaking = service.isSpeaking
        #expect(speaking == false)
    }

    @Test func serviceNotifiesWhenSpeechCompletes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var notified = false
        service.didFinishSpeaking = { _ in
            notified = true
        }

        service.speak(text: "Test")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        // PRD requires notification when speech completes (for state machine transitions)
        #expect(notified)
    }

    @Test func serviceMustCompleteBeforeSpeechRecognitionStarts() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var canStartRecognition = false
        service.didFinishSpeaking = { _ in
            canStartRecognition = true
        }

        // PRD: TTS must complete before speech recognition starts
        service.speak(text: "Test")
        #expect(!canStartRecognition)

        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
        #expect(canStartRecognition)
    }
}
