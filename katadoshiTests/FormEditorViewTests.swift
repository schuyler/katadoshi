//
//  FormEditorViewTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/3/25.
//

import Testing
import Foundation
import SwiftUI
@testable import katadoshi

/// Unit tests for FormEditorView business logic
///
/// Tests the FormEditorView according to PRD Section 9.2 (Form Editor View)
/// and Section 9.4 (UI Design Conventions).
///
/// **Architectural Decision (Groucho):**
/// - View state (@State properties) are private implementation details
/// - All view behavior is tested via UI tests in FormEditorViewUITests.swift
/// - FormStore validation/parsing tests belong in FormStoreTests.swift
///
/// **Test Coverage:**
/// - Mode enum behavior (create vs edit)
/// - Form data preservation in edit mode
///
/// All interactive behavior (navigation, buttons, text input, validation) is tested
/// in FormEditorViewUITests.swift using XCUITest.
@MainActor
struct FormEditorViewTests {

    // MARK: - Test Helpers

    /// Creates a valid test form
    private func makeValidForm(
        id: UUID = UUID(),
        title: String = "Test Form",
        moves: [String] = ["Move 1", "Move 2"],
        dateCreated: Date = Date(),
        lastPracticed: Date = Date()
    ) -> katadoshi.Form {
        katadoshi.Form(id: id, title: title, moves: moves, dateCreated: dateCreated, lastPracticed: lastPracticed)
    }

    // MARK: - Mode Enum Tests

    @Test func editModePreservesFormData() {
        let originalForm = makeValidForm(
            id: UUID(),
            title: "Heian Shodan",
            moves: ["Ready position", "Left down block", "Step forward right punch"],
            dateCreated: Date(timeIntervalSince1970: 1699000000),
            lastPracticed: Date(timeIntervalSince1970: 1699100000)
        )
        let view = FormEditorView(mode: .edit(originalForm))

        // Verify the form is stored correctly in the mode enum
        switch view.mode {
        case .create:
            Issue.record("Mode should be edit")
        case .edit(let form):
            #expect(form.id == originalForm.id)
            #expect(form.title == originalForm.title)
            #expect(form.moves == originalForm.moves)
            #expect(form.dateCreated == originalForm.dateCreated)
            #expect(form.lastPracticed == originalForm.lastPracticed)
        }
    }
}
