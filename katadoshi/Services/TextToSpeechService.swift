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
    /// - Parameter success: true if speech completed normally, false if cancelled
    var didFinishSpeaking: ((Bool) -> Void)? { get set }
}

/// Text-to-speech service using AVSpeechSynthesizer
///
/// This service provides speech synthesis capabilities for reading form move instructions
/// aloud during practice sessions. It coordinates with SpeechRecognitionService via
/// completion callbacks to enforce mutual exclusion (PRD Section 5.3).
@MainActor
class TextToSpeechService: NSObject, TextToSpeechServiceProtocol {
    private let synthesizer: AVSpeechSynthesizer

    /// Callback invoked when speech finishes (true) or is cancelled (false)
    var didFinishSpeaking: ((Bool) -> Void)?

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

    /// Stops speaking immediately
    func stop() {
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
        didFinishSpeaking?(true)
    }

    /// Called when the synthesizer cancels speaking an utterance
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        didFinishSpeaking?(false)
    }
}
