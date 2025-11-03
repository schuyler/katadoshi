//
//  PracticeView.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import SwiftUI

/// Practice session view for voice-controlled form practice
/// PRD Section 9.3: Practice view with state machine and voice commands
///
/// NOTE: This is a stub implementation. Full implementation pending.
struct PracticeView: View {
    let form: Form

    var body: some View {
        VStack(spacing: 16) {
            Text("PracticeView")
                .font(.title)
                .bold()

            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This view will provide voice-controlled practice for:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(form.title)
                .font(.body)
                .bold()

            Text("\(form.moves.count) moves")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle(form.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let sampleForm = Form(
        id: UUID(),
        title: "Heian Shodan",
        moves: [
            "Ready position",
            "Left down block",
            "Step forward right punch",
            "Turn 180 degrees left down block"
        ],
        dateCreated: Date(),
        lastPracticed: Date()
    )

    return NavigationStack {
        PracticeView(form: sampleForm)
    }
}
