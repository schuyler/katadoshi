//
//  SpeechRecognitionService.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import AVFoundation
import Foundation
import Speech

/// Protocol abstracting SFSpeechRecognizer for testability
protocol SpeechRecognizerProtocol {
    /// Indicates whether the recognizer is available
    var isAvailable: Bool { get }

    /// Creates a recognition task with the given request
    /// - Parameters:
    ///   - request: The speech recognition request
    ///   - resultHandler: Handler called with recognition results or errors
    /// - Returns: The recognition task
    func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask
}

/// Production wrapper for SFSpeechRecognizer
class SpeechRecognizerWrapper: SpeechRecognizerProtocol {
    private let recognizer: SFSpeechRecognizer

    /// Creates a wrapper for the given recognizer
    init?(locale: Locale = .current) {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            return nil
        }
        self.recognizer = recognizer
    }

    var isAvailable: Bool {
        recognizer.isAvailable
    }

    func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request, resultHandler: resultHandler)
    }
}

/// Protocol defining speech recognition service capabilities
protocol SpeechRecognitionServiceProtocol {
    /// Indicates whether the service is currently listening
    var isListening: Bool { get }

    /// Callback invoked when a voice command is recognized
    /// - Parameter command: The recognized VoiceCommand
    var didRecognizeCommand: ((VoiceCommand) -> Void)? { get set }

    /// Callback invoked when speech recognition permission is denied or restricted
    var onPermissionDenied: (() -> Void)? { get set }

    /// Callback invoked when speech recognition is unavailable (no recognizer or audio error)
    var onRecognitionUnavailable: (() -> Void)? { get set }

    /// Starts listening for voice commands
    func startListening()

    /// Stops listening for voice commands
    func stopListening()
}

/// Speech recognition service using Apple Speech Framework
///
/// This service provides voice command recognition for controlling practice sessions.
/// It recognizes 8 voice commands (start, begin, next, go, back, repeat, stop, pause)
/// and reports them via the didRecognizeCommand callback.
///
/// **Architectural Responsibility:**
/// This service is a simple command recognition service. It does NOT manage session
/// states or validate state-command combinations. That responsibility belongs to
/// PracticeSessionManager per PRD Section 5.4.
///
/// **Service Responsibilities:**
/// - Start/stop audio recognition (isListening: Bool)
/// - Parse transcripts into VoiceCommand enum values
/// - Report recognized commands via didRecognizeCommand callback
/// - Handle permission and availability errors
///
/// **Out of Scope:**
/// - Session state management (Ready, Speaking, Listening, Paused, Completed)
/// - State-command validation (which commands are valid in which states)
/// - Coordinating mutual exclusion with TTS (PracticeSessionManager handles this)
@MainActor
class SpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol {
    private let recognizer: SpeechRecognizerProtocol?
    private let audioEngine: AVAudioEngine
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var _isListening = false
    private var isRestarting = false  // Prevents multiple restart attempts
    private var bufferCount = 0  // Diagnostic: count audio buffers received

    /// Indicates whether the service is currently listening
    var isListening: Bool {
        return _isListening
    }

    /// Callback invoked when a voice command is recognized
    var didRecognizeCommand: ((VoiceCommand) -> Void)?

    /// Callback invoked when speech recognition permission is denied or restricted
    var onPermissionDenied: (() -> Void)?

    /// Callback invoked when speech recognition is unavailable
    var onRecognitionUnavailable: (() -> Void)?

    /// Creates a new SpeechRecognitionService
    /// - Parameters:
    ///   - recognizer: The SpeechRecognizerProtocol to use (defaults to system default for current locale)
    ///   - audioEngine: The AVAudioEngine to use (defaults to a new instance)
    convenience override init() {
        self.init(recognizer: SpeechRecognizerWrapper(locale: .current),
                  audioEngine: AVAudioEngine())
    }

    init(recognizer: SpeechRecognizerProtocol?,
         audioEngine: AVAudioEngine) {
        self.recognizer = recognizer
        self.audioEngine = audioEngine
        super.init()
    }

    /// Starts listening for voice commands
    func startListening() {
        // Check authorization status
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        guard authStatus == .authorized else {
            onPermissionDenied?()
            return
        }

        // Check recognizer availability
        guard let recognizer = recognizer, recognizer.isAvailable else {
            onRecognitionUnavailable?()
            return
        }

        // If already listening, stop first to restart cleanly
        if _isListening {
            stopListening()
        }

        // Audio session is configured once by PracticeViewModel
        // Do NOT reconfigure here - see: https://stackoverflow.com/questions/53147291

        // Set up recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            onRecognitionUnavailable?()
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .confirmation  // Short commands like "next", "stop"
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false  // Allow cloud for reliability
        }

        // Start audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        print("🎤 KATADOSHI: Audio format - rate: \(recordingFormat.sampleRate), channels: \(recordingFormat.channelCount)")

        // Check for valid recording format
        guard recordingFormat.sampleRate > 0 else {
            print("🎤 KATADOSHI: Invalid audio format (sampleRate=0)")
            onRecognitionUnavailable?()
            return
        }

        bufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.bufferCount += 1
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            onRecognitionUnavailable?()
            return
        }

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error as NSError? {
                // Error 216 = "Request was canceled" - intentional stop, ignore
                // Error 301 = "Recognition request was canceled" - intentional stop, ignore
                // Error 1101 = iOS 18 local speech recording issue - ignore (console noise)
                if error.code == 216 || error.code == 301 || error.code == 1101 {
                    return
                }

                // Error 1110 = "No speech detected" - restart listening if still active
                if error.code == 1110 {
                    Task { @MainActor in
                        // Only restart if we're still supposed to be listening
                        // (command recognition or state change may have stopped us)
                        guard self._isListening else { return }
                        guard !self.isRestarting else { return }
                        self.isRestarting = true

                        print("🎤 KATADOSHI: No speech (1110) after \(self.bufferCount) buffers, restarting in 200ms...")
                        self.stopListening()
                        try? await Task.sleep(nanoseconds: 200_000_000)  // 200ms
                        self.isRestarting = false
                        self.startListening()
                    }
                    return
                }

                print("🎤 KATADOSHI: Recognition error \(error.code): \(error.localizedDescription)")
                Task { @MainActor in
                    self.onRecognitionUnavailable?()
                }
                return
            }

            guard let result = result else { return }

            // Parse the transcript for commands
            let transcript = result.bestTranscription.formattedString
            print("🎤 KATADOSHI: Transcript: '\(transcript)' (final: \(result.isFinal))")

            Task { @MainActor in
                if let command = parseCommand(from: transcript) {
                    print("🎤 KATADOSHI: Command recognized: \(command)")
                    self.didRecognizeCommand?(command)
                }
            }
        }

        _isListening = true
    }

    /// Stops listening for voice commands
    func stopListening() {
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Always stop engine and remove tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // Reset the audio engine to clear any lingering state.
        // This ensures a clean slate for the next startListening() call
        // and prevents conflicts when transitioning back from TTS.
        //
        // References:
        // - Stack Overflow (How to correctly set up AVAudioSession with both services):
        //   https://stackoverflow.com/questions/53147291
        //   "Always remove the input node tap before installing a new one, even after
        //   successful completion."
        //
        // - Stack Overflow (AVAudioSession issue when using SFSpeechRecognizer after TTS):
        //   https://stackoverflow.com/questions/43457132
        audioEngine.reset()

        // Clean up recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Do NOT deactivate audio session - it's configured once by PracticeViewModel
        // Deactivating/reactivating causes iOS 18 audio session conflicts
        // See: https://stackoverflow.com/questions/53147291

        _isListening = false
    }
}
