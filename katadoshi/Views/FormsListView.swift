//
//  FormsListView.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import SwiftUI

/// Main forms list view - displays all saved forms and provides navigation to practice and editor
/// PRD Section 9.1: Forms List View
/// PRD Section 9.4: UI Design Conventions
struct FormsListView: View {
    @Environment(FormStore.self) private var formStore
    @State private var showingNewFormEditor = false
    @State private var formToEdit: Form?

    var body: some View {
        NavigationStack {
            Group {
                if formStore.forms.isEmpty {
                    EmptyStateView()
                } else {
                    FormsList(formStore: formStore, formToEdit: $formToEdit)
                }
            }
            .navigationTitle("Kata Dōshi")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewFormEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Form")
                }
            }
            .sheet(isPresented: $showingNewFormEditor) {
                NavigationStack {
                    FormEditorView(mode: .create)
                        .environment(formStore)
                }
            }
            .sheet(item: $formToEdit) { form in
                NavigationStack {
                    FormEditorView(mode: .edit(form))
                        .environment(formStore)
                }
            }
        }
    }
}

/// Separate list component for better organization
private struct FormsList: View {
    let formStore: FormStore
    @Binding var formToEdit: Form?

    var body: some View {
        List {
            ForEach(formStore.forms) { form in
                NavigationLink {
                    PracticeView(form: form)
                } label: {
                    FormRowView(form: form)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        formToEdit = form
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        formToEdit = form
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .onDelete(perform: deleteForm)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteForm(at offsets: IndexSet) {
        offsets.forEach { index in
            let form = formStore.forms[index]
            // FormStore.deleteForm is idempotent and won't throw for typical cases
            try? formStore.deleteForm(id: form.id)
        }
    }
}

/// Form row component displaying title and last practiced date
/// PRD Section 9.1: Form title (bold, 18pt), Last practiced date (gray, 14pt), Chevron right
private struct FormRowView: View {
    let form: Form

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(form.title)
                .font(.system(size: 18, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            Text(formatLastPracticed(form.lastPracticed, created: form.dateCreated))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(form.title), \(formatLastPracticed(form.lastPracticed, created: form.dateCreated))")
        .accessibilityHint("Double tap to practice this form")
    }

    private func formatLastPracticed(_ date: Date, created: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        // If lastPracticed equals dateCreated exactly, form has never been practiced separately
        if date == created {
            return "Created \(formatter.localizedString(for: created, relativeTo: Date()))"
        }

        // Otherwise show when it was last practiced
        return "Practiced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

/// Empty state view shown when no forms exist
/// PRD Section 9.1: "No Forms Yet" + "Tap + to create your first form" subtitle
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No Forms Yet")
                .font(.headline)

            Text("Tap + to create your first form")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No Forms Yet. Tap + to create your first form")
    }
}

#Preview("Empty State") {
    let formStore = FormStore(userDefaults: UserDefaults(suiteName: "preview.empty")!)

    return FormsListView()
        .environment(formStore)
}

#Preview("With Forms") {
    let formStore = FormStore(userDefaults: UserDefaults(suiteName: "preview.withforms")!)

    // Create sample forms
    let form1 = Form(
        id: UUID(),
        title: "Heian Shodan",
        moves: ["Ready position", "Left down block", "Step forward right punch"],
        dateCreated: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
        lastPracticed: Date().addingTimeInterval(-2 * 24 * 60 * 60) // 2 days ago
    )

    let form2 = Form(
        id: UUID(),
        title: "Heian Nidan",
        moves: ["Ready position", "Left down block"],
        dateCreated: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
        lastPracticed: Date().addingTimeInterval(-14 * 24 * 60 * 60) // Never practiced separately
    )

    try? formStore.saveForm(form: form1)
    try? formStore.saveForm(form: form2)

    return FormsListView()
        .environment(formStore)
}
