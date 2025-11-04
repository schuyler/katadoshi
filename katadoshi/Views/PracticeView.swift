//
//  PracticeView.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import SwiftUI

/// Practice session view for voice-controlled form practice
///
/// This view displays the current move instruction and provides voice-controlled
/// navigation through a martial arts form. It integrates with PracticeSessionManager
/// via PracticeViewModel for state management.
///
/// **UI Components (PRD Section 9.3):**
/// - Always visible: Move counter, instruction text, stop button
/// - State-dependent: Status indicators, start/resume buttons, timeout prompt
///
/// **State Machine (PRD Section 5.4):**
/// - Ready → Speaking → Listening → (loop or Paused/Completed)
///
/// **PRD References:**
/// - Section 9.3: Practice View specifications
/// - Section 9.4: UI Design System & Conventions
/// - Section 6.1: Voice command behaviors
struct PracticeView: View {

    // MARK: - Environment

    @Environment(FormStore.self) private var formStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    private let form: Form
    @State private var viewModel: PracticeViewModel?

    // MARK: - Initialization

    init(form: Form) {
        self.form = form
        // ViewModel will be created in .task with proper environment
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                practiceContent(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            // Initialize ViewModel once with environment FormStore
            if viewModel == nil {
                viewModel = PracticeViewModel(
                    form: form,
                    formStore: formStore
                )
            }
        }
        .onChange(of: viewModel?.shouldDismiss ?? false) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel?.sessionState) { _, newState in
            // Disable idle timer when session enters speaking state (PRD Section 5.4)
            // This is idempotent - safe to call on every speaking transition
            if newState == .speaking {
                disableIdleTimer()
            }
        }
        .onDisappear {
            // Clean up session when view disappears
            viewModel?.stopSession()
            // Re-enable idle timer to restore normal screen behavior (PRD Section 5.4)
            enableIdleTimer()
        }
    }

    // MARK: - Screen Management

    /// Disables idle timer to keep screen on during practice (PRD Section 5.4)
    ///
    /// Called when practice session transitions from ready to speaking state.
    /// Prevents screen from auto-locking to maintain speech recognition functionality.
    private func disableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    /// Re-enables idle timer to restore normal screen behavior (PRD Section 5.4)
    ///
    /// Called when view disappears to ensure screen auto-lock returns to normal.
    /// This is an idempotent operation - safe to call multiple times.
    private func enableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Private Views

    @ViewBuilder
    private func practiceContent(viewModel: PracticeViewModel) -> some View {
        VStack(spacing: 32) {
            // Top spacer
            Spacer()

            // Move counter (always visible)
            MoveCounterView(
                currentIndex: viewModel.currentMoveIndex,
                totalMoves: viewModel.totalMoves
            )

            Spacer()

            // Current instruction text (always visible)
            InstructionView(text: viewModel.currentMoveText)

            Spacer()

            // State indicator (conditional on state)
            StateIndicatorView(
                state: viewModel.sessionState,
                showTimeout: viewModel.showTimeout
            )

            Spacer()

            // Action buttons (conditional on state)
            ActionButtonsView(
                state: viewModel.sessionState,
                onStartTap: viewModel.handleManualStart
            )

            // Bottom spacer to push stop button down
            Spacer()

            // Stop button (always visible)
            StopButton(action: {
                viewModel.handleManualStop()
                dismiss()
            })
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(Color.white)
        .alert(
            "Microphone Permission Required",
            isPresented: Binding(
                get: { viewModel.error == .permissionDenied },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                viewModel.clearError()
            }
            Button("Cancel", role: .cancel) {
                viewModel.clearError()
                dismiss()
            }
        } message: {
            Text("Kata Dōshi needs microphone access for voice commands. Please enable it in Settings.")
        }
        .alert(
            "Service Unavailable",
            isPresented: Binding(
                get: { viewModel.error == .serviceUnavailable },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
                dismiss()
            }
        } message: {
            Text("Voice recognition is currently unavailable. Please try again later.")
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error == .emptyForm || viewModel.error == .invalidMoveIndex },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
                dismiss()
            }
        } message: {
            Text(viewModel.error?.description ?? "An error occurred")
        }
    }
}

// MARK: - Sub-Components

/// Move counter display: "Move X of Y"
private struct MoveCounterView: View {
    let currentIndex: Int
    let totalMoves: Int

    var body: some View {
        Text("Move \(currentIndex + 1) of \(totalMoves)")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .accessibilityLabel("Move counter")
            .accessibilityValue("Move \(currentIndex + 1) of \(totalMoves)")
    }
}

/// Current instruction text display
private struct InstructionView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Current instruction")
            .accessibilityValue(text)
    }
}

/// State indicator (Listening, Speaking, Paused, etc.)
private struct StateIndicatorView: View {
    let state: SessionState
    let showTimeout: Bool

    var body: some View {
        VStack(spacing: 8) {
            if showTimeout {
                // Timeout prompt (PRD Section 6.3)
                Text("Still there? Say 'next' to continue")
                    .font(.body)
                    .foregroundColor(.orange)
                    .accessibilityLabel("Timeout prompt")
            } else {
                // State-dependent indicators
                switch state {
                case .ready:
                    Text("Say 'start' to begin")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Ready state prompt")

                case .listening:
                    Text("Listening...")
                        .font(.body)
                        .foregroundColor(.green)
                        .accessibilityLabel("Listening state")

                case .speaking:
                    Text("Speaking...")
                        .font(.body)
                        .foregroundColor(.blue)
                        .accessibilityLabel("Speaking state")

                case .paused:
                    VStack(spacing: 4) {
                        Text("Paused")
                            .font(.body)
                            .foregroundColor(.orange)
                            .accessibilityLabel("Paused state")
                        Text("Say 'start' to resume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .completed:
                    VStack(spacing: 4) {
                        Text("Form Complete!")
                            .font(.body)
                            .foregroundColor(.green)
                            .accessibilityLabel("Completed state")
                        Text("Say 'start' or 'begin' to restart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

/// Action buttons (Start/Resume) - conditional on state
private struct ActionButtonsView: View {
    let state: SessionState
    let onStartTap: () -> Void

    var body: some View {
        if state == .ready || state == .paused || state == .completed {
            Button(action: onStartTap) {
                Text(buttonLabel)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(buttonLabel + " button")
        }
    }

    private var buttonLabel: String {
        switch state {
        case .paused:
            return "Resume"
        case .completed:
            return "Restart"
        default:
            return "Start"
        }
    }
}

/// Stop button (always visible)
private struct StopButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Stop")
                .font(.body.weight(.semibold))
                .frame(minWidth: 120)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .accessibilityLabel("Stop button")
    }
}

// MARK: - Previews

#Preview("Ready State") {
    let sampleForm = Form(
        title: "Heian Shodan",
        moves: [
            "Ready position",
            "Left down block",
            "Step forward right punch",
            "Turn 180 degrees left down block"
        ]
    )

    return NavigationStack {
        PracticeView(form: sampleForm)
            .environment(FormStore(userDefaults: .standard))
    }
}

#Preview("Listening State") {
    let sampleForm = Form(
        title: "Heian Shodan",
        moves: [
            "Ready position",
            "Left down block",
            "Step forward right punch"
        ]
    )

    // Note: Preview can't easily simulate listening state without test infrastructure
    // This shows Ready state - actual listening state requires running app
    return NavigationStack {
        PracticeView(form: sampleForm)
            .environment(FormStore(userDefaults: .standard))
    }
}
