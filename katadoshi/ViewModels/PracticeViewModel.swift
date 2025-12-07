//
//  PracticeViewModel.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import AVFoundation
import Foundation
import Observation
import Speech

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

    /// Whether permissions have been requested
    private(set) var permissionsRequested: Bool = false

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

    // MARK: - Permission Handling

    /// Request microphone and speech recognition permissions
    ///
    /// This method should be called when the view appears to ensure
    /// permission dialogs are shown before the user tries to start.
    /// Without explicit requests, iOS won't show permission toggles in Settings.
    func requestPermissions() {
        guard !permissionsRequested else { return }
        permissionsRequested = true

        // Request speech recognition permission first
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self = self else { return }

                switch status {
                case .authorized:
                    // Speech recognition authorized, now request microphone
                    self.requestMicrophonePermission()
                case .denied, .restricted:
                    self.error = .permissionDenied
                case .notDetermined:
                    // Should not happen after requesting, but handle gracefully
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    /// Request microphone permission via AVAudioSession
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self = self else { return }
                if granted {
                    // Configure audio session ONCE for the entire practice session
                    // This must be done once, not repeatedly - see:
                    // https://stackoverflow.com/questions/53147291
                    self.configureAudioSession()
                    // Both permissions granted - start listening for initial voice command
                    self.sessionManager.startListeningForInitialCommand()
                } else {
                    self.error = .permissionDenied
                }
            }
        }
    }

    /// Configure audio session once for TTS and speech recognition
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure audio session for both TTS playback and speech recognition recording.
            // .mixWithOthers allows TTS and speech recognition to transition smoothly
            // without abrupt audio session interruptions during turn-taking.
            //
            // References:
            // - Stack Overflow (AVSpeechSynthesizer doesn't work after recording):
            //   https://stackoverflow.com/questions/43637714
            //   "For AVSpeechSynthesizer, the audio session has to be set to Playback with
            //   MixWithOthers options. For SFSpeechRecognizer, it should be set to
            //   PlayAndRecord with MixWithOthers options."
            //
            // - Stack Overflow (AVSpeechSynthesizer does not speak after using SFSpeechRecognizer):
            //   https://stackoverflow.com/questions/40270738
            //
            // - Stack Overflow (How to correctly set up AVAudioSession with both services):
            //   https://stackoverflow.com/questions/53147291
            //   "Configure your audio session in viewDidLoad (or initialization), not
            //   repeatedly during speech recognition."
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            try audioSession.setActive(true)
        } catch {
            // Non-fatal - services may still work
            print("[AudioSession] Configuration failed: \(error)")
        }
    }
}
