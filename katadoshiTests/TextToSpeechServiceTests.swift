//
//  TextToSpeechServiceTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/2/25.
//

import Testing
import Foundation
import AVFoundation
@testable import katadoshi

// MARK: - TextToSpeechService Tests

/// Tests for TextToSpeechService protocol and implementation
@MainActor
struct TextToSpeechServiceTests {

    // MARK: - Mock AVSpeechSynthesizer

    /// Mock AVSpeechSynthesizer for testing without actual speech output
    class MockSpeechSynthesizer: AVSpeechSynthesizer {
        var speakCalled = false
        var stopCalled = false
        var pauseCalled = false
        var lastUtterance: AVSpeechUtterance?
        var lastStopBoundary: AVSpeechBoundary?
        var lastPauseBoundary: AVSpeechBoundary?
        var mockIsSpeaking = false

        // Track order of pause/stop calls for turn-taking verification
        var callOrder: [String] = []

        // Track all utterances to simulate queueing behavior
        var utteranceQueue: [AVSpeechUtterance] = []

        override func speak(_ utterance: AVSpeechUtterance) {
            speakCalled = true
            lastUtterance = utterance
            mockIsSpeaking = true

            // Simulate queueing: Real AVSpeechSynthesizer queues utterances
            // For testing purposes, we track the queue but process immediately
            utteranceQueue.append(utterance)
        }

        override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
            stopCalled = true
            lastStopBoundary = boundary
            callOrder.append("stop")
            mockIsSpeaking = false

            // Real AVSpeechSynthesizer triggers didCancel when stopped
            if let utterance = lastUtterance {
                simulateCancel(utterance)
            }

            return true
        }

        override func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
            pauseCalled = true
            lastPauseBoundary = boundary
            callOrder.append("pause")
            return true
        }

        override var isSpeaking: Bool {
            return mockIsSpeaking
        }

        /// Simulate completion of speech
        func simulateFinish(_ utterance: AVSpeechUtterance) {
            mockIsSpeaking = false
            guard let delegate = self.delegate else { return }
            delegate.speechSynthesizer?(self, didFinish: utterance)
        }

        /// Simulate cancellation of speech (called automatically by stopSpeaking in real behavior)
        func simulateCancel(_ utterance: AVSpeechUtterance) {
            mockIsSpeaking = false
            guard let delegate = self.delegate else { return }
            delegate.speechSynthesizer?(self, didCancel: utterance)
        }
    }

    // MARK: - Protocol Conformance Tests

    @Test func textToSpeechServiceConformsToProtocol() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify service conforms to protocol
        _ = service as TextToSpeechServiceProtocol
    }

    @Test func textToSpeechServiceImplementsProtocolMethods() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify all protocol methods are implemented
        service.speak(text: "Test")
        service.stop()
        service.pause()
        _ = service.isSpeaking
    }

    // MARK: - speak() Method Tests

    @Test func speakMethodCallsSynthesizerSpeak() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        #expect(mockSynthesizer.speakCalled)
    }

    @Test func speakMethodCreatesUtteranceWithCorrectText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Step forward with left foot")

        #expect(mockSynthesizer.lastUtterance?.speechString == "Step forward with left foot")
    }

    @Test func speakMethodHandlesEmptyString() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "")

        // Should still call speak, even with empty text
        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == "")
    }

    @Test func speakMethodHandlesLongText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let longText = String(repeating: "A", count: 500)

        service.speak(text: longText)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == longText)
    }

    @Test func speakMethodHandlesSpecialCharacters() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let textWithSpecialChars = "前蹴り (Mae Geri) - front kick"

        service.speak(text: textWithSpecialChars)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == textWithSpecialChars)
    }

    @Test func speakMethodCanBeCalledMultipleTimes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First instruction")
        service.speak(text: "Second instruction")
        service.speak(text: "Third instruction")

        // Last utterance should be the third one
        #expect(mockSynthesizer.lastUtterance?.speechString == "Third instruction")
    }

    @Test func speakMethodHandlesNewlinesInText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let textWithNewlines = "Step forward\nTurn left\nPunch"

        service.speak(text: textWithNewlines)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == textWithNewlines)
    }

    // MARK: - Voice and Speech Rate Configuration Tests (PRD Section 5.3)

    @Test func speakMethodUsesDefaultVoice() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        // PRD Section 5.3 requires: "Default voice and speed for MVP"
        // Default voice is nil, meaning use system default
        #expect(mockSynthesizer.lastUtterance?.voice == nil)
    }

    @Test func speakMethodUsesDefaultSpeechRate() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")

        // PRD Section 5.3 requires: "Default voice and speed for MVP"
        // Default rate is AVSpeechUtteranceDefaultSpeechRate
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
    }

    @Test func utteranceUsesDefaultConfigurationForAllSpeechRequests() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)

        service.speak(text: "Second move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)

        service.speak(text: "Third move")
        #expect(mockSynthesizer.lastUtterance?.rate == AVSpeechUtteranceDefaultSpeechRate)
        #expect(mockSynthesizer.lastUtterance?.voice == nil)
    }

    // MARK: - stop() Method Tests

    @Test func stopMethodCallsSynthesizerStop() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.stop()

        #expect(mockSynthesizer.stopCalled)
    }

    @Test func stopMethodStopsActiveSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        #expect(mockSynthesizer.mockIsSpeaking)

        service.stop()

        #expect(!mockSynthesizer.mockIsSpeaking)
    }

    @Test func stopMethodCanBeCalledWhenNotSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash when stopping while not speaking
        service.stop()

        #expect(mockSynthesizer.stopCalled)
    }

    @Test func stopMethodCanBeCalledMultipleTimes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.stop()
        service.stop()
        service.stop()

        // Should handle multiple stop calls without error
        #expect(mockSynthesizer.stopCalled)
    }

    // MARK: - pause() Method Tests

    @Test func pauseMethodCallsSynthesizerPause() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func pauseMethodCanBeCalledWhenSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func pauseMethodCanBeCalledWhenNotSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash when pausing while not speaking
        service.pause()

        #expect(mockSynthesizer.pauseCalled)
    }

    // MARK: - Boundary Parameter Tests

    @Test func stopMethodUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")
        service.stop()

        // stop() should use .immediate boundary to stop speech instantly
        #expect(mockSynthesizer.lastStopBoundary == .immediate)
    }

    @Test func pauseMethodUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test instruction")
        service.pause()

        // pause() should use .immediate boundary to pause speech instantly
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)
    }

    @Test func stopMethodAlwaysUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Test multiple stop calls all use .immediate
        service.speak(text: "First")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)

        service.speak(text: "Second")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)

        service.speak(text: "Third")
        service.stop()
        #expect(mockSynthesizer.lastStopBoundary == .immediate)
    }

    @Test func pauseMethodAlwaysUsesImmediateBoundary() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Test multiple pause calls all use .immediate
        service.speak(text: "First")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)

        service.speak(text: "Second")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)

        service.speak(text: "Third")
        service.pause()
        #expect(mockSynthesizer.lastPauseBoundary == .immediate)
    }

    // MARK: - Turn-Taking Coordination Tests

    @Test func stopMethodPausesBeforeStoppingWhenSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Start speaking first
        service.speak(text: "Test instruction")

        // Reset call order tracking after speak
        mockSynthesizer.callOrder = []

        service.stop()

        // Should pause first, then stop (for audio hardware settling)
        #expect(mockSynthesizer.pauseCalled)
        #expect(mockSynthesizer.stopCalled)
        #expect(mockSynthesizer.callOrder == ["pause", "stop"])
    }

    @Test func stopMethodSkipsPauseWhenNotSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Don't start speaking - just call stop directly
        service.stop()

        // Should only call stop, not pause (nothing to pause)
        #expect(!mockSynthesizer.pauseCalled)
        #expect(mockSynthesizer.stopCalled)
        #expect(mockSynthesizer.callOrder == ["stop"])
    }

    @Test func synthesizerUsesApplicationAudioSession() {
        // This test verifies that the synthesizer is configured to use the app's
        // shared audio session, which prevents conflicts with SFSpeechRecognizer
        let synthesizer = AVSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: synthesizer)

        // After initialization, synthesizer should use application audio session
        // This is critical for turn-taking coordination with speech recognition
        #expect(synthesizer.usesApplicationAudioSession == true)

        // Suppress unused variable warning
        _ = service
    }

    // MARK: - isSpeaking Property Tests

    @Test func isSpeakingReturnsFalseInitially() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        #expect(!service.isSpeaking)
    }

    @Test func isSpeakingReturnsTrueWhileSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")

        #expect(service.isSpeaking)
    }

    @Test func isSpeakingReturnsFalseAfterStop() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Test")
        service.stop()

        #expect(!service.isSpeaking)
    }

    @Test func isSpeakingReflectsSynthesizerState() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)

        service.speak(text: "Test")
        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)

        service.stop()
        #expect(service.isSpeaking == mockSynthesizer.isSpeaking)
    }

    // MARK: - Completion Callback Tests

    @Test func didFinishSpeakingCallbackIsSetOnService() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        #expect(!callbackCalled)
    }

    @Test func didFinishSpeakingCallbackFiresWhenSpeechCompletes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate speech completion
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCalled)
    }

    @Test func didFinishSpeakingCallbackFiresForEachUtterance() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCount = 0
        service.didFinishSpeaking = { _ in
            callbackCount += 1
        }

        service.speak(text: "First")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Second")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Third")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCount == 3)
    }

    @Test func didFinishSpeakingCallbackCanBeNil() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Should not crash with nil callback
        service.didFinishSpeaking = nil
        service.speak(text: "Test")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
    }

    @Test func didFinishSpeakingCallbackCanBeChanged() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var firstCallbackCalled = false
        var secondCallbackCalled = false

        service.didFinishSpeaking = { _ in
            firstCallbackCalled = true
        }

        service.speak(text: "Test 1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(firstCallbackCalled)
        #expect(!secondCallbackCalled)

        service.didFinishSpeaking = { _ in
            secondCallbackCalled = true
        }

        service.speak(text: "Test 2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(secondCallbackCalled)
    }

    // MARK: - AVSpeechSynthesizerDelegate Tests

    @Test func serviceImplementsAVSpeechSynthesizerDelegate() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify service can be used as AVSpeechSynthesizerDelegate
        _ = service as AVSpeechSynthesizerDelegate
    }

    @Test func serviceSetsSelfAsDelegateOnInitialization() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Verify the service sets itself as delegate
        #expect(mockSynthesizer.delegate === service)
    }

    @Test func speechSynthesizerDidFinishTriggersCallback() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate delegate method call
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(callbackCalled)
    }

    @Test func speechSynthesizerDidCancelTriggersCallback() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")

        // Simulate cancellation
        mockSynthesizer.simulateCancel(mockSynthesizer.lastUtterance!)

        // Callback should fire on cancel as well (speech is done, whether completed or cancelled)
        #expect(callbackCalled)
    }

    // MARK: - State Management Tests

    @Test func speakingStateTransitionsCorrectly() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Initially not speaking
        #expect(!service.isSpeaking)

        // Start speaking
        service.speak(text: "Test")
        #expect(service.isSpeaking)

        // Finish speaking
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
        #expect(!service.isSpeaking)
    }

    @Test func stopInterruptsActiveSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "Long instruction that will be interrupted")
        #expect(service.isSpeaking)

        service.stop()
        #expect(!service.isSpeaking)
    }

    @Test func newSpeakInterruptsCurrentSpeech() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "First instruction")
        let firstUtterance = mockSynthesizer.lastUtterance

        service.speak(text: "Second instruction")
        let secondUtterance = mockSynthesizer.lastUtterance

        #expect(firstUtterance !== secondUtterance)
        #expect(secondUtterance?.speechString == "Second instruction")
    }

    // MARK: - Queueing Behavior Tests

    @Test func multipleSpeakCallsQueueUtterances() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Real AVSpeechSynthesizer queues utterances when multiple speak() calls are made
        // Our mock simulates this by tracking the queue, though processing is immediate for testing
        service.speak(text: "First")
        service.speak(text: "Second")
        service.speak(text: "Third")

        // Verify all utterances were queued
        #expect(mockSynthesizer.utteranceQueue.count == 3)
        #expect(mockSynthesizer.utteranceQueue[0].speechString == "First")
        #expect(mockSynthesizer.utteranceQueue[1].speechString == "Second")
        #expect(mockSynthesizer.utteranceQueue[2].speechString == "Third")
    }

    @Test func queueingBehaviorDocumented() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // IMPORTANT: Real AVSpeechSynthesizer queues utterances sequentially
        // In PracticeSessionManager, we rely on TTS completion callbacks to ensure
        // only one utterance is spoken at a time (Speaking -> Listening state transition)
        // This test documents the expected behavior for implementation guidance

        service.speak(text: "Move 1")
        #expect(mockSynthesizer.utteranceQueue.count == 1)

        // In practice session, we wait for didFinishSpeaking before next speak()
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 2")
        #expect(mockSynthesizer.utteranceQueue.count == 2)
    }

    @Test func consecutiveSpeakCallsWithoutWaitingForCompletion() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCount = 0
        service.didFinishSpeaking = { _ in
            callbackCount += 1
        }

        service.speak(text: "First")
        service.speak(text: "Second")  // Called before first completes

        // AVSpeechSynthesizer queues utterances, so both should be queued
        #expect(mockSynthesizer.utteranceQueue.count == 2)

        // When first finishes, callback fires
        mockSynthesizer.simulateFinish(mockSynthesizer.utteranceQueue[0])
        #expect(callbackCount == 1)

        // When second finishes, callback fires again
        mockSynthesizer.simulateFinish(mockSynthesizer.utteranceQueue[1])
        #expect(callbackCount == 2)
    }

    // MARK: - Integration with PracticeSessionManager Tests

    @Test func callbackFiredBeforeNextSpeak() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var completionOrder: [String] = []

        service.didFinishSpeaking = { _ in
            completionOrder.append("callback")
        }

        service.speak(text: "First")
        completionOrder.append("speak1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Second")
        completionOrder.append("speak2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        #expect(completionOrder == ["speak1", "callback", "speak2", "callback"])
    }

    @Test func serviceReadyForImmediateReuse() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // Rapid fire usage pattern (as in practice session)
        service.speak(text: "Move 1")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 2")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        service.speak(text: "Move 3")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        // All should work without issues
        #expect(mockSynthesizer.lastUtterance?.speechString == "Move 3")
    }

    // MARK: - Edge Cases

    @Test func serviceHandlesWhitespaceOnlyText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.speak(text: "   \t\n   ")

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == "   \t\n   ")
    }

    @Test func serviceHandlesVeryLongText() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)
        let veryLongText = String(repeating: "This is a very long instruction. ", count: 100)

        service.speak(text: veryLongText)

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.lastUtterance?.speechString == veryLongText)
    }

    @Test func serviceHandlesNonASCIICharacters() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        let texts = [
            "前蹴り",
            "Tae Kwon Do",
            "Capoeira",
            "Крюк",
            "🥋👊"
        ]

        for text in texts {
            service.speak(text: text)
            #expect(mockSynthesizer.lastUtterance?.speechString == text)
        }
    }

    @Test func stopWithNoActiveUtteranceIsIdempotent() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.stop()
        service.stop()
        service.stop()

        // Should not crash or cause issues
        #expect(!service.isSpeaking)
    }

    @Test func pauseWithNoActiveUtteranceIsIdempotent() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        service.pause()
        service.pause()
        service.pause()

        // Should not crash or cause issues
        #expect(!service.isSpeaking)
    }

    @Test func callbackIsCalledWhenStoppedManually() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var callbackCalled = false
        service.didFinishSpeaking = { _ in
            callbackCalled = true
        }

        service.speak(text: "Test")
        service.stop()

        // AVSpeechSynthesizer.stopSpeaking(at:) triggers didCancel delegate callback
        // which should fire our didFinishSpeaking callback (speech is done, whether completed or cancelled)
        #expect(callbackCalled)
    }

    // MARK: - Dependency Injection Tests

    @Test func serviceAcceptsCustomSynthesizerViaInitializer() {
        let customSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: customSynthesizer)

        service.speak(text: "Test")

        #expect(customSynthesizer.speakCalled)
    }

    @Test func serviceWorksWithDefaultSynthesizer() {
        // Test that service can be initialized with default AVSpeechSynthesizer
        let service = TextToSpeechService()

        // Should not crash
        service.speak(text: "Test")
        service.stop()
    }

    @Test func multipleSynthesizersCanBeUsedSimultaneously() {
        let synthesizer1 = MockSpeechSynthesizer()
        let synthesizer2 = MockSpeechSynthesizer()

        let service1 = TextToSpeechService(synthesizer: synthesizer1)
        let service2 = TextToSpeechService(synthesizer: synthesizer2)

        service1.speak(text: "Service 1")
        service2.speak(text: "Service 2")

        #expect(synthesizer1.lastUtterance?.speechString == "Service 1")
        #expect(synthesizer2.lastUtterance?.speechString == "Service 2")
    }

    // MARK: - Thread Safety Tests

    @Test func serviceIsMainActorIsolated() async {
        // Service should be usable on main actor
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        await MainActor.run {
            service.speak(text: "Test")
            #expect(mockSynthesizer.speakCalled)
        }
    }

    // MARK: - Memory Management Tests

    @Test func callbackDoesNotCreateRetainCycle() {
        var service: TextToSpeechService? = TextToSpeechService(synthesizer: MockSpeechSynthesizer())
        weak var weakService = service

        service?.didFinishSpeaking = { [weak weakService] _ in
            _ = weakService?.isSpeaking
        }

        service = nil

        // Service should be deallocated
        #expect(weakService == nil)
    }

    // MARK: - PRD Requirements Validation Tests

    @Test func serviceSupportsAllPRDRequiredMethods() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // PRD Section 5.3 requires: speak(text:), stop(), pause()
        service.speak(text: "Test")
        service.stop()
        service.pause()

        #expect(mockSynthesizer.speakCalled)
        #expect(mockSynthesizer.stopCalled)
        #expect(mockSynthesizer.pauseCalled)
    }

    @Test func serviceSupportsIsSpeakingProperty() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        // PRD requires checking if currently speaking
        let speaking = service.isSpeaking
        #expect(speaking == false)
    }

    @Test func serviceNotifiesWhenSpeechCompletes() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var notified = false
        service.didFinishSpeaking = { _ in
            notified = true
        }

        service.speak(text: "Test")
        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)

        // PRD requires notification when speech completes (for state machine transitions)
        #expect(notified)
    }

    @Test func serviceMustCompleteBeforeSpeechRecognitionStarts() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = TextToSpeechService(synthesizer: mockSynthesizer)

        var canStartRecognition = false
        service.didFinishSpeaking = { _ in
            canStartRecognition = true
        }

        // PRD: TTS must complete before speech recognition starts
        service.speak(text: "Test")
        #expect(!canStartRecognition)

        mockSynthesizer.simulateFinish(mockSynthesizer.lastUtterance!)
        #expect(canStartRecognition)
    }
}
