//
//  ContentView.swift
//  katadoshi
//
//  Created by Schuyler Erle on 11/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Kata Dōshi")
                        .font(.largeTitle)
                        .bold()
                    Text("Form Companion for Martial Artists")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Development Phase") {
                    Text("Phase 1 MVP: Core Services Implementation")
                        .font(.caption)
                    Text("✓ Form Model & Store")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("✓ TextToSpeechService")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("✓ SpeechRecognitionService")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("⏳ PracticeSessionManager (next)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                #if DEBUG
                Section("Debug Tools") {
                    NavigationLink {
                        SpeechTestHarnessView()
                    } label: {
                        Label("Speech Recognition Test Harness", systemImage: "waveform.badge.mic")
                    }

                    Text("Manual testing tools for authorization flows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                #endif

                Section("Coming Soon") {
                    Label("Forms List", systemImage: "list.bullet")
                        .foregroundColor(.secondary)
                    Label("Form Editor", systemImage: "square.and.pencil")
                        .foregroundColor(.secondary)
                    Label("Practice View", systemImage: "play.circle")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Kata Dōshi")
        }
    }
}

#Preview {
    ContentView()
}
