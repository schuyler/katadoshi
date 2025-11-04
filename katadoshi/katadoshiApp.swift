//
//  katadoshiApp.swift
//  katadoshi
//
//  Created by Schuyler Erle on 11/2/25.
//

import SwiftUI

@main
struct katadoshiApp: App {
    @State private var formStore = FormStore()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // In test mode, use an isolated FormStore
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                TestEnvironmentView()
            } else {
                FormsListView()
                    .environment(formStore)
            }
            #else
            FormsListView()
                .environment(formStore)
            #endif
        }
    }

    #if DEBUG
    /// Test environment view that properly manages FormStore lifecycle
    private struct TestEnvironmentView: View {
        @State private var formStore: FormStore

        init() {
            // Initialize FormStore once during init, not in body
            let testStore = FormStore(userDefaults: UserDefaults(suiteName: "UI_TESTING")!)
            testStore.testOnlyClearForms()

            // Inject specific test data based on launch arguments
            if ProcessInfo.processInfo.arguments.contains("PRACTICE_VIEW_TESTING") {
                katadoshiApp.injectPracticeViewTestData(into: testStore)
            }

            if ProcessInfo.processInfo.arguments.contains("FORMS_LIST_TESTING") {
                katadoshiApp.injectFormsListTestData(into: testStore)
            }

            if ProcessInfo.processInfo.arguments.contains("FORM_EDITOR_TESTING") {
                katadoshiApp.injectFormEditorTestData(into: testStore)
            }

            _formStore = State(initialValue: testStore)
        }

        var body: some View {
            FormsListView()
                .environment(formStore)
        }
    }

    /// Injects test data for PracticeView tests
    @MainActor
    private static func injectPracticeViewTestData(into store: FormStore) {
        // Check for custom form title from environment
        let formTitle = ProcessInfo.processInfo.environment["TEST_FORM_TITLE"] ?? "Test Form"

        let testForm = Form(
            title: formTitle,
            moves: ["Move 1", "Move 2", "Move 3"]
        )
        store.testOnlyInsertForm(form: testForm)
    }

    /// Injects test data for FormsListView tests
    @MainActor
    private static func injectFormsListTestData(into store: FormStore) {
        // Multiple forms for list display and manipulation tests
        store.testOnlyInsertForm(form: Form(
            title: "Test Form 1",
            moves: ["Move A", "Move B"]
        ))

        store.testOnlyInsertForm(form: Form(
            title: "Test Form 2",
            moves: ["Move C", "Move D"]
        ))

        store.testOnlyInsertForm(form: Form(
            title: "Test Form 3",
            moves: ["Move E", "Move F"]
        ))

        // Form with long title for display tests
        store.testOnlyInsertForm(form: Form(
            title: "This is a very long form title that should test proper display and truncation behavior in the list view",
            moves: ["Move 1"]
        ))

        // Form with special characters for edge case tests
        store.testOnlyInsertForm(form: Form(
            title: "Form with 特殊 characters & symbols!",
            moves: ["Move 1"]
        ))

        // Many forms for scrolling tests (10 total)
        for i in 6...10 {
            store.testOnlyInsertForm(form: Form(
                title: "Form \(i)",
                moves: ["Move 1", "Move 2"]
            ))
        }
    }

    /// Injects test data for FormEditorView edit mode tests
    @MainActor
    private static func injectFormEditorTestData(into store: FormStore) {
        // Pre-existing form for edit mode tests
        store.testOnlyInsertForm(form: Form(
            title: "Editable Form",
            moves: ["Original Move 1", "Original Move 2", "Original Move 3"]
        ))

        // Additional form for delete tests
        store.testOnlyInsertForm(form: Form(
            title: "Form to Delete",
            moves: ["Move 1"]
        ))
    }
    #endif
}
