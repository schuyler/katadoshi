//
//  PracticeSessionManager.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import Foundation

/// Represents the state of a practice session
enum SessionState: Equatable {
    /// Session has not started or has been reset
    case ready

    /// Speaking a move instruction via TTS
    case speaking

    /// Listening for voice commands
    case listening

    /// Session is paused by user
    case paused

    /// All moves have been completed
    case completed
}

/// Protocol for practice session management
@MainActor
protocol PracticeSessionManagerProtocol {
    /// Current form being practiced
    var currentForm: Form { get }

    /// Index of the current move within the form
    var currentMoveIndex: Int { get }

    /// Current session state
    var state: SessionState { get }

    /// Current move instruction text
    var currentMove: String { get }

    /// Callback when session state changes
    var onStateChanged: ((SessionState) -> Void)? { get set }

    /// Callback when move changes (index, text)
    var onMoveChanged: ((Int, String) -> Void)? { get set }

    /// Callback when 2-minute listening timeout occurs
    var onTimeout: (() -> Void)? { get set }

    /// Callback when service errors occur
    var onError: ((PracticeSessionManagerError) -> Void)? { get set }

    /// Callback when session is stopped
    var onExit: (() -> Void)? { get set }

    /// Starts or resumes the practice session
    func start() throws

    /// Handles incoming voice commands
    func handleCommand(_ command: VoiceCommand)

    /// Stops the practice session
    func stop()

    /// Pauses the practice session
    func pause()

    /// Starts listening for initial voice command in Ready/Paused/Completed states
    /// Call this after permissions are granted to enable voice-controlled session start
    func startListeningForInitialCommand()
}

// Note: The protocols TextToSpeechServiceProtocol and SpeechRecognitionServiceProtocol
// are defined in TextToSpeechService.swift and SpeechRecognitionService.swift respectively

/// Manages practice session state and coordinates TTS and speech recognition services
///
/// **Architectural Responsibility:**
/// PracticeSessionManager coordinates TTS and SpeechRecognition services, enforces
/// mutual exclusion (one service runs at a time), manages session state transitions,
/// and validates commands based on current state.
///
/// **State Machine:**
/// - Ready: Initial state, waiting for start command
/// - Speaking: Playing move instruction via TTS
/// - Listening: Waiting for voice command (with 2-minute timeout)
/// - Paused: Paused by user, waiting for resume
/// - Completed: All moves have been executed
///
/// **Mutual Exclusion:**
/// TTS (speaking) and speech recognition (listening) NEVER run simultaneously.
/// The manager enforces this constraint via setupServiceCallbacks().
///
/// **Voice Commands by State:**
/// - Ready/Paused/Completed: .start, .begin, .stop
/// - Speaking: .stop (only)
/// - Listening: .next, .go, .back, .repeat, .pause, .stop
@MainActor
class PracticeSessionManager: PracticeSessionManagerProtocol {
    // MARK: - Properties

    private var ttsService: TextToSpeechServiceProtocol
    private var speechService: SpeechRecognitionServiceProtocol

    private(set) var currentForm: Form
    private(set) var currentMoveIndex: Int = 0
    private(set) var state: SessionState = .ready

    var onStateChanged: ((SessionState) -> Void)?
    var onMoveChanged: ((Int, String) -> Void)?
    var onTimeout: (() -> Void)?
    var onError: ((PracticeSessionManagerError) -> Void)?
    var onExit: (() -> Void)?

    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 120  // 2 minutes
    private let ttsToSpeechDelayNanoseconds: UInt64

    /// State to transition to after current TTS announcement finishes
    /// Used for completion ("Joombi"), pause ("Paused"), timeout ("Still there?")
    private var stateAfterSpeaking: SessionState?

    // MARK: - Initialization

    /// Creates a new PracticeSessionManager
    /// - Parameters:
    ///   - form: The form to practice
    ///   - ttsService: Text-to-speech service for move instructions
    ///   - speechService: Speech recognition service for voice commands
    ///   - ttsToSpeechDelayNanoseconds: Delay after TTS finishes before starting speech recognition (default 500ms)
    init(form: Form,
         ttsService: TextToSpeechServiceProtocol,
         speechService: SpeechRecognitionServiceProtocol,
         ttsToSpeechDelayNanoseconds: UInt64 = 500_000_000) {
        self.currentForm = form
        self.ttsService = ttsService
        self.speechService = speechService
        self.ttsToSpeechDelayNanoseconds = ttsToSpeechDelayNanoseconds
        setupServiceCallbacks()
    }

    // MARK: - Computed Properties

    var currentMove: String {
        guard currentMoveIndex < currentForm.moves.count else {
            return ""
        }
        return currentForm.moves[currentMoveIndex]
    }

    // MARK: - Public Methods

    /// Starts or resumes the practice session
    func start() throws {
        // Validate form has moves
        guard !currentForm.moves.isEmpty else {
            throw PracticeSessionManagerError.emptyForm
        }

        // Only start if in Ready, Paused, or Completed states
        guard [.ready, .paused, .completed].contains(state) else {
            return
        }

        // Reset to beginning if coming from Completed state
        if state == .completed {
            currentMoveIndex = 0
            notifyMoveChanged()
        }

        speakCurrentMove()
    }

    /// Handles incoming voice commands
    /// - Parameter command: The voice command to process
    func handleCommand(_ command: VoiceCommand) {
        // Validate command for current state
        guard isCommandValid(command) else {
            return
        }

        // Handle stop command (valid in all states)
        if command == .stop {
            stop()
            return
        }

        // Handle state-specific commands
        switch state {
        case .ready:
            // Handle start/begin commands
            switch command {
            case .start, .begin:
                try? start()
            default:
                break
            }

        case .speaking:
            // Only stop command is valid in speaking state
            break

        case .listening:
            // Stop listening before processing navigation
            speechService.stopListening()
            resetTimeoutTimer()

            switch command {
            case .next, .go:
                moveNext()
            case .back:
                movePrevious()
            case .repeat:
                repeatCurrent()
            case .pause:
                // Announce pause so user knows it worked (they're not looking at screen)
                speakAnnouncement("Paused", thenTransitionTo: .paused)
            case .start, .begin:
                speakCurrentMove()
            case .stop:
                stop()
            }

        case .paused:
            // Handle resume with start/begin from paused state
            speechService.stopListening()
            switch command {
            case .start, .begin:
                speakCurrentMove()
            default:
                break
            }

        case .completed:
            // Handle restart with start/begin from completed state
            speechService.stopListening()
            switch command {
            case .start, .begin:
                currentMoveIndex = 0
                notifyMoveChanged()
                speakCurrentMove()
            default:
                break
            }
        }
    }

    /// Stops the practice session from any state
    func stop() {
        stopServices()
        onExit?()
    }

    /// Pauses the practice session from listening state
    func pause() {
        guard state == .listening else {
            return
        }

        // Announce pause so user knows it worked (they're not looking at screen)
        speakAnnouncement("Paused", thenTransitionTo: .paused)
    }

    /// Starts listening for initial voice command in Ready/Paused/Completed states
    ///
    /// This enables voice-controlled session start by listening for "start" or "begin"
    /// commands before the session has started. Should be called after permissions are granted.
    func startListeningForInitialCommand() {
        // Only start listening in states that accept start/begin commands
        guard [.ready, .paused, .completed].contains(state) else {
            return
        }

        // Don't restart if already listening
        guard !speechService.isListening else {
            return
        }

        speechService.startListening()
    }

    // MARK: - Internal Methods (for testing)

    /// Handles 2-minute timeout during listening state
    internal func handleTimeout() {
        guard state == .listening else {
            return
        }

        // Speak audio prompt since user isn't looking at screen
        // After speaking, return to listening state
        speakAnnouncement("Still there?", thenTransitionTo: .listening)

        onTimeout?()
    }

    // MARK: - Private Methods

    /// Sets up service callbacks for coordination
    private func setupServiceCallbacks() {
        let delayNanos = ttsToSpeechDelayNanoseconds
        // TTS completion triggers state transition and listening
        ttsService.didFinishSpeaking = { [weak self] _ in
            guard let self = self, self.state == .speaking else { return }

            // Check if we have a pending state transition (completion, pause, timeout)
            let targetState = self.stateAfterSpeaking
            self.stateAfterSpeaking = nil

            if delayNanos > 0 {
                Task { @MainActor in
                    // Allow audio hardware to fully release from TTS before starting recognition
                    // See: https://stackoverflow.com/questions/43457132
                    try? await Task.sleep(nanoseconds: delayNanos)
                    guard self.state == .speaking else { return }  // Re-check after delay

                    // Transition to target state if specified, then start listening
                    if let targetState = targetState {
                        self.transitionTo(targetState)
                    }
                    self.startListening()
                }
            } else {
                // No delay (used in tests)
                if let targetState = targetState {
                    self.transitionTo(targetState)
                }
                self.startListening()
            }
        }

        // Command recognition triggers TTS stop and processes command
        speechService.didRecognizeCommand = { [weak self] command in
            guard let self = self else { return }
            self.handleCommand(command)
        }

        // Permission denied error
        speechService.onPermissionDenied = { [weak self] in
            guard let self = self else { return }
            self.stopServices()
            self.transitionTo(.ready)
            self.onError?(.permissionDenied)
        }

        // Service unavailable error
        speechService.onRecognitionUnavailable = { [weak self] in
            guard let self = self else { return }
            self.stopServices()
            self.transitionTo(.ready)
            self.onError?(.serviceUnavailable)
        }
    }

    /// Transitions to a new state and notifies listeners
    private func transitionTo(_ newState: SessionState) {
        guard state != newState else { return }
        state = newState
        onStateChanged?(newState)
    }

    /// Speaks the current move instruction
    private func speakCurrentMove() {
        // Stop speech recognition before speaking (mutual exclusion)
        speechService.stopListening()
        resetTimeoutTimer()

        stateAfterSpeaking = nil  // Normal flow: speaking -> listening
        transitionTo(.speaking)
        ttsService.speak(text: currentMove)
    }

    /// Speaks an announcement and transitions to the specified state after TTS completes
    /// Used for audio feedback that users can hear without looking at the screen
    private func speakAnnouncement(_ text: String, thenTransitionTo targetState: SessionState) {
        speechService.stopListening()
        resetTimeoutTimer()

        stateAfterSpeaking = targetState
        transitionTo(.speaking)
        ttsService.speak(text: text)
    }

    /// Starts listening for voice commands
    private func startListening() {
        // Stop TTS before listening (mutual exclusion)
        ttsService.stop()

        transitionTo(.listening)
        speechService.startListening()
        startTimeoutTimer()
    }

    /// Stops both services
    private func stopServices() {
        ttsService.stop()
        speechService.stopListening()
        resetTimeoutTimer()
    }

    /// Validates whether a command is valid for the current state
    private func isCommandValid(_ command: VoiceCommand) -> Bool {
        switch state {
        case .ready:
            return [.start, .begin, .stop].contains(command)
        case .speaking:
            return command == .stop
        case .listening:
            return [.next, .go, .back, .repeat, .pause, .stop, .start, .begin].contains(command)
        case .paused:
            return [.start, .begin, .stop].contains(command)
        case .completed:
            return [.start, .begin, .stop].contains(command)
        }
    }

    /// Advances to the next move and speaks it
    private func moveNext() {
        currentMoveIndex += 1

        // Check if we've reached the end
        if currentMoveIndex >= currentForm.moves.count {
            currentMoveIndex = currentForm.moves.count - 1
            // Announce completion with "Joombi" (ready position) so user knows they're done
            // User isn't looking at screen during practice, needs audio feedback
            speakAnnouncement("Joombi", thenTransitionTo: .completed)
            return
        }

        notifyMoveChanged()
        speakCurrentMove()
    }

    /// Goes to the previous move and speaks it
    private func movePrevious() {
        // Stay at first move if already there
        if currentMoveIndex > 0 {
            currentMoveIndex -= 1
        }

        notifyMoveChanged()
        speakCurrentMove()
    }

    /// Repeats the current move
    private func repeatCurrent() {
        notifyMoveChanged()
        speakCurrentMove()
    }

    /// Notifies listeners that the current move has changed
    private func notifyMoveChanged() {
        onMoveChanged?(currentMoveIndex, currentMove)
    }

    /// Starts the 2-minute timeout timer
    private func startTimeoutTimer() {
        resetTimeoutTimer()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTimeout()
            }
        }
    }

    /// Resets the timeout timer
    private func resetTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
