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
/// NOTE: This is a stub implementation. Full implementation pending.
struct FormEditorView: View {
    enum Mode {
        case create
        case edit(Form)
    }

    let mode: Mode

    var body: some View {
        VStack(spacing: 16) {
            Text("FormEditorView")
                .font(.title)
                .bold()

            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This view will allow creating and editing forms")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "New Form"
        case .edit:
            return "Edit Form"
        }
    }
}

#Preview("Create Mode") {
    NavigationStack {
        FormEditorView(mode: .create)
    }
}

#Preview("Edit Mode") {
    let sampleForm = Form(
        id: UUID(),
        title: "Heian Shodan",
        moves: ["Move 1", "Move 2", "Move 3"],
        dateCreated: Date(),
        lastPracticed: Date()
    )

    return NavigationStack {
        FormEditorView(mode: .edit(sampleForm))
    }
}
