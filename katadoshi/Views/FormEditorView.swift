//
//  FormEditorView.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import SwiftUI

/// Form editor view for creating and editing forms
/// PRD Section 9.2: Form editor with title and moves input
///
/// Architecture notes:
/// - Computed properties (navigationTitle, isSaveEnabled) are private implementation details
/// - Validation occurs at save time via FormStore
/// - Save button disabled only for empty inputs (basic validation)
struct FormEditorView: View {
    enum Mode {
        case create
        case edit(Form)
    }

    // MARK: - Dependencies
    @Environment(FormStore.self) private var formStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - View State
    let mode: Mode
    @State private var title: String = ""
    @State private var movesText: String = ""
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var isInitialized = false

    // MARK: - Body
    var body: some View {
        SwiftUI.Form {
            Section {
                TextField("Form Name", text: $title)
                    .accessibilityLabel("Form Title")

                ZStack(alignment: .topLeading) {
                    if movesText.isEmpty {
                        Text("Enter moves, one per line")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $movesText)
                        .font(.system(.body, design: .monospaced))
                        .opacity(movesText.isEmpty ? 0.5 : 1.0)
                }
                .frame(minHeight: 120)
                .accessibilityLabel("Form Moves")
            } header: {
                Text("Form Details")
            } footer: {
                Text("Enter moves one per line. Maximum 200 characters per move.")
                    .font(.caption)
            }

            if isEditMode {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Form")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Delete Form")
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityLabel("Cancel")
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveForm()
                }
                .disabled(!isSaveEnabled)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Save")
            }
        }
        .alert("Delete Form", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteForm()
            }
        } message: {
            Text("Are you sure you want to delete this form? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            if !isInitialized {
                initializeFormData()
                isInitialized = true
            }
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "New Form"
        case .edit:
            return "Edit Form"
        }
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var isSaveEnabled: Bool {
        // Basic validation: check for non-empty content
        // Full validation (move length, etc.) happens at save time in FormStore
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMoves = movesText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && !trimmedMoves.isEmpty
    }

    // MARK: - Actions

    private func initializeFormData() {
        switch mode {
        case .create:
            title = ""
            movesText = ""
        case .edit(let form):
            title = form.title
            movesText = form.moves.joined(separator: "\n")
        }
    }

    private func saveForm() {
        do {
            let parsedMoves = try formStore.parseMoves(from: movesText)

            switch mode {
            case .create:
                let newForm = Form(title: title, moves: parsedMoves)
                try formStore.saveForm(form: newForm)
            case .edit(let existingForm):
                var updatedForm = existingForm
                updatedForm.title = title
                updatedForm.moves = parsedMoves
                try formStore.updateForm(form: updatedForm)
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func deleteForm() {
        guard case .edit(let form) = mode else { return }

        do {
            try formStore.deleteForm(id: form.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Previews

#Preview("Create Mode") {
    NavigationStack {
        FormEditorView(mode: .create)
            .environment(FormStore(userDefaults: UserDefaults(suiteName: "preview")!))
    }
}

#Preview("Edit Mode") {
    let sampleForm = Form(
        id: UUID(),
        title: "Heian Shodan",
        moves: ["Ready stance", "Left downward block", "Right stepping punch", "Turn 180°", "Right downward block"],
        dateCreated: Date(),
        lastPracticed: Date()
    )

    return NavigationStack {
        FormEditorView(mode: .edit(sampleForm))
            .environment(FormStore(userDefaults: UserDefaults(suiteName: "preview")!))
    }
}
