//
//  PracticeViewModel.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import Foundation
import Observation

/// View model that wraps PracticeSessionManager for SwiftUI integration
///
/// This class bridges the callback-based PracticeSessionManager with SwiftUI's
/// reactive @Observable pattern, providing state management for PracticeView.
///
/// **Responsibilities:**
/// - Register callbacks with PracticeSessionManager
/// - Expose reactive state properties for SwiftUI
/// - Update FormStore.lastPracticed on every session start
/// - Handle errors and propagate them to the view
/// - Manage view lifecycle (dismissal, cleanup)
///
/// **PRD References:**
/// - Section 9.3: PracticeView specifications
/// - Section 5.4: PracticeSessionManager integration
/// - Section 8.1: Error handling requirements
@MainActor
@Observable
class PracticeViewModel {

    // MARK: - Public Properties (Reactive State)

    /// Current session state from PracticeSessionManager
    private(set) var sessionState: SessionState = .ready

    /// Current move index in the form
    private(set) var currentMoveIndex: Int = 0

    /// Current move text being displayed
    private(set) var currentMoveText: String = ""

    /// Total number of moves in the form
    let totalMoves: Int

    /// Whether to show timeout prompt (PRD Section 6.3)
    private(set) var showTimeout: Bool = false

    /// Current error from manager, if any
    private(set) var error: PracticeSessionManagerError?

    /// Whether view should dismiss (triggered by onExit callback)
    private(set) var shouldDismiss: Bool = false

    // MARK: - Private Properties

    private var sessionManager: PracticeSessionManagerProtocol
    private let formStore: FormStore
    private let form: Form

    // MARK: - Initialization

    /// Initialize PracticeViewModel with form, store, and session manager
    ///
    /// - Parameters:
    ///   - form: The form to practice
    ///   - formStore: Store for updating lastPracticed date
    ///   - sessionManager: Session manager (injectable for testing, defaults to production)
    init(
        form: Form,
        formStore: FormStore,
        sessionManager: PracticeSessionManagerProtocol? = nil
    ) {
        self.form = form
        self.formStore = formStore
        self.totalMoves = form.moves.count
        self.currentMoveText = form.moves.first ?? ""

        // Create session manager if not provided (dependency injection)
        if let manager = sessionManager {
            self.sessionManager = manager
        } else {
            // Production: Create real services and manager
            let ttsService = TextToSpeechService()
            let speechService = SpeechRecognitionService()
            self.sessionManager = PracticeSessionManager(
                form: form,
                ttsService: ttsService,
                speechService: speechService
            )
        }

        // Register callbacks with session manager
        registerCallbacks()
    }

    // MARK: - Callback Registration

    /// Register callbacks with PracticeSessionManager for reactive updates
    private func registerCallbacks() {
        // onStateChanged: Update session state and clear timeout on state transitions
        sessionManager.onStateChanged = { [weak self] newState in
            self?.sessionState = newState
            // Clear timeout flag on any state change (PRD Section 6.3)
            self?.showTimeout = false
        }

        // onMoveChanged: Update current move index and text
        sessionManager.onMoveChanged = { [weak self] index, text in
            self?.currentMoveIndex = index
            self?.currentMoveText = text
        }

        // onTimeout: Set timeout flag to show prompt
        sessionManager.onTimeout = { [weak self] in
            self?.showTimeout = true
        }

        // onError: Capture errors for display in view
        sessionManager.onError = { [weak self] error in
            self?.error = error
        }

        // onExit: Set dismissal flag for navigation
        sessionManager.onExit = { [weak self] in
            self?.shouldDismiss = true
        }
    }

    // MARK: - Public Methods

    /// Start the practice session
    ///
    /// This method calls the session manager's start() method and updates
    /// the form's lastPracticed date in FormStore.
    ///
    /// **PRD Section 5.2:** "lastPracticed: Updated when practice session starts"
    /// This updates on EVERY start call, not just the first one.
    ///
    /// - Throws: PracticeSessionManagerError if session cannot start
    func startSession() throws {
        // Call manager to start session
        try sessionManager.start()

        // Update lastPracticed date (PRD Section 5.2)
        var updatedForm = form
        updatedForm.lastPracticed = Date()
        try? formStore.updateForm(form: updatedForm)
    }

    /// Stop the practice session
    ///
    /// This method calls the session manager's stop() method to cleanly
    /// end the practice session.
    func stopSession() {
        sessionManager.stop()
    }

    /// Handle manual start button tap
    ///
    /// This method wraps startSession() and captures any errors,
    /// suitable for button actions that don't throw.
    func handleManualStart() {
        do {
            try startSession()
        } catch let error as PracticeSessionManagerError {
            self.error = error
        } catch {
            // Unexpected error type - shouldn't happen but handle gracefully
            self.error = .serviceUnavailable
        }
    }

    /// Handle manual stop button tap
    ///
    /// This method wraps stopSession() for consistency with handleManualStart().
    func handleManualStop() {
        stopSession()
    }

    /// Clear the current error
    ///
    /// This method is called when an error alert is dismissed,
    /// allowing the user to retry or navigate away.
    func clearError() {
        error = nil
    }
}
