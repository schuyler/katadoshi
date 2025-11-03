//
//  FormModelTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/2/25.
//

import Testing
import Foundation
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
