//
//  TextToSpeechService.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import AVFoundation
import Foundation

/// Protocol defining text-to-speech service capabilities
protocol TextToSpeechServiceProtocol {
    /// Speaks the given text aloud
    /// - Parameter text: The text to speak
    func speak(text: String)

    /// Stops speaking immediately
    func stop()

    /// Pauses speaking at the current position
    func pause()

    /// Indicates whether the service is currently speaking
    var isSpeaking: Bool { get }

    /// Callback invoked when speech finishes or is cancelled
    /// - Parameter text: The text that was spoken
    var didFinishSpeaking: ((String) -> Void)? { get set }
}

/// Text-to-speech service using AVSpeechSynthesizer
///
/// This service provides speech synthesis capabilities for reading form move instructions
/// aloud during practice sessions. It coordinates with SpeechRecognitionService via
/// completion callbacks to enforce mutual exclusion (PRD Section 5.3).
@MainActor
class TextToSpeechService: NSObject, TextToSpeechServiceProtocol {
    private let synthesizer: AVSpeechSynthesizer

    /// Callback invoked when speech finishes or is cancelled
    /// - Parameter text: The text that was spoken
    var didFinishSpeaking: ((String) -> Void)?

    /// Indicates whether the synthesizer is currently speaking
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    /// Creates a new TextToSpeechService
    /// - Parameter synthesizer: The AVSpeechSynthesizer to use (defaults to a new instance)
    init(synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()) {
        self.synthesizer = synthesizer
        super.init()
        self.synthesizer.delegate = self
        // Use the app's shared audio session instead of synthesizer's own session.
        // This prevents audio session conflicts with SFSpeechRecognizer during turn-taking.
        //
        // References:
        // - WWDC 2020 "Create a seamless speech experience in your apps":
        //   https://developer.apple.com/videos/play/wwdc2020/10022/
        //   "You can set [usesApplicationAudioSession] to false to delegate away the
        //   management of speech audio to the system."
        //
        // - Apple Developer Documentation:
        //   https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession
        //
        // - Stack Overflow (alternating TTS and speech recognition):
        //   https://stackoverflow.com/questions/48722346
        self.synthesizer.usesApplicationAudioSession = true
    }

    /// Speaks the given text using default voice and speech rate
    /// - Parameter text: The text to speak
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)

        // PRD Section 5.3: Use default voice and speed for MVP
        utterance.voice = nil  // nil uses system default voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
    }

    /// Stops speaking gracefully
    /// Uses pause-then-stop pattern to avoid audio session conflicts during turn-taking
    func stop() {
        // Pause first to allow audio hardware to settle before full stop.
        // This prevents abrupt audio session transitions that can interfere
        // with subsequent speech recognition.
        //
        // References:
        // - Stack Overflow (alternating between AVSpeechSynthesis and AVAudioSession):
        //   https://stackoverflow.com/questions/48722346
        //   "Pausing the synthesizer before stopping it allows to deactivate the
        //   audio session without errors."
        //
        // - Stack Overflow (AVSpeechSynthesizer doesn't work after recording):
        //   https://stackoverflow.com/questions/43637714
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Pauses speaking at the current position
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    /// Called when the synthesizer finishes speaking an utterance
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishSpeaking?(utterance.speechString)
    }

    /// Called when the synthesizer cancels speaking an utterance
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        didFinishSpeaking?(utterance.speechString)
    }
}
