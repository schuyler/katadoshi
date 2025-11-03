//
//  FormStore.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import Foundation
import SwiftUI

/// Manages persistence and CRUD operations for Form models using UserDefaults
@MainActor
class FormStore: ObservableObject {
    /// Published array of forms that triggers UI updates when changed
    @Published private(set) var forms: [Form] = []

    private let userDefaults: UserDefaults
    private let formsKey = "forms"

    /// Creates a new FormStore with the specified UserDefaults instance
    /// - Parameter userDefaults: The UserDefaults instance to use for persistence (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadForms()
    }

    /// Loads forms from UserDefaults
    private func loadForms() {
        guard let data = userDefaults.data(forKey: formsKey) else {
            forms = []
            return
        }

        do {
            let decoder = JSONDecoder()
            forms = try decoder.decode([Form].self, from: data)
        } catch {
            // Handle corrupted data gracefully by starting with empty array
            forms = []
        }
    }

    /// Persists the current forms array to UserDefaults
    private func persist() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(forms)
        userDefaults.set(data, forKey: formsKey)
    }

    /// Validates a form according to PRD requirements
    /// - Parameter form: The form to validate
    /// - Throws: FormStoreError if validation fails
    private func validate(form: Form) throws {
        // Validate title is not empty after trimming whitespace
        let trimmedTitle = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw FormStoreError.emptyTitle
        }

        // Validate moves array is not empty
        if form.moves.isEmpty {
            throw FormStoreError.emptyMoves
        }

        // Validate each move is not empty after trimming and does not exceed 200 characters
        for move in form.moves {
            let trimmedMove = move.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check for empty or whitespace-only moves
            if trimmedMove.isEmpty {
                throw FormStoreError.emptyMoves
            }

            // Check move length (after trimming)
            if trimmedMove.count > 200 {
                throw FormStoreError.moveTooLong(length: trimmedMove.count)
            }
        }
    }

    /// Parses a multi-line string into an array of move instructions
    /// - Parameter input: Multi-line string with one move per line
    /// - Returns: Array of parsed and validated move strings
    /// - Throws: FormStoreError if parsing/validation fails
    ///
    /// Parsing rules (from PRD Section 5.2):
    /// - Split input on newlines
    /// - Trim whitespace from each line
    /// - Skip empty lines
    /// - Reject lines longer than 200 characters
    /// - Minimum 1 move required
    func parseMoves(from input: String) throws -> [String] {
        // Split on all newline types (\n, \r\n, \r)
        let lines = input.components(separatedBy: CharacterSet.newlines)

        var moves: [String] = []

        for line in lines {
            // Trim whitespace
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Reject lines longer than 200 characters (after trimming)
            if trimmed.count > 200 {
                throw FormStoreError.moveTooLong(length: trimmed.count)
            }

            moves.append(trimmed)
        }

        // Require at least 1 move
        if moves.isEmpty {
            throw FormStoreError.emptyMoves
        }

        return moves
    }

    /// Saves a new form to the store
    /// - Parameter form: The form to save
    /// - Throws: FormStoreError if validation fails or duplicate ID exists
    func saveForm(form: Form) throws {
        // Check for duplicate ID
        if forms.contains(where: { $0.id == form.id }) {
            throw FormStoreError.duplicateID
        }

        // Normalize whitespace in title and moves
        var normalizedForm = form
        normalizedForm.title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedForm.moves = form.moves.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        try validate(form: normalizedForm)
        forms.append(normalizedForm)
        try persist()
    }

    /// Updates an existing form in the store
    /// - Parameter form: The form to update (matched by id)
    /// - Throws: FormStoreError if form not found or validation fails
    func updateForm(form: Form) throws {
        guard let index = forms.firstIndex(where: { $0.id == form.id }) else {
            throw FormStoreError.formNotFound
        }

        // Normalize whitespace in title and moves
        var normalizedForm = form
        normalizedForm.title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedForm.moves = form.moves.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        try validate(form: normalizedForm)
        forms[index] = normalizedForm
        try persist()
    }

    /// Deletes a form from the store
    /// - Parameter id: The UUID of the form to delete
    /// - Throws: Error if persistence fails
    func deleteForm(id: UUID) throws {
        forms.removeAll(where: { $0.id == id })
        try persist()
    }
}
