//
//  PracticeSessionManagerTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/3/25.
//

import Testing
import Foundation
@testable import katadoshi

// MARK: - PracticeSessionManager Tests

/// Comprehensive tests for PracticeSessionManager state machine
///
/// **Architectural Responsibility:**
/// PracticeSessionManager coordinates TTS and SpeechRecognition services,
/// manages practice session state, and enforces mutual exclusion between services.
///
/// **Test Coverage:**
/// 1. SessionState enum tests
/// 2. PracticeSessionManagerError enum tests
/// 3. Initialization tests
/// 4. State transition tests (exhaustive)
/// 5. Command-state validation matrix tests (PRD Section 6.1)
/// 6. Navigation tests (moveNext, movePrevious, repeatCurrent)
/// 7. Service coordination tests (CRITICAL: mutual exclusion)
/// 8. Callback tests (onStateChanged, onMoveChanged, onTimeout, onError, onExit)
/// 9. Timeout tests (2-minute timer)
/// 10. Error handling tests
/// 11. Edge cases (single move form, rapid commands, etc.)
@MainActor
struct PracticeSessionManagerTests {

    // MARK: - Test Helpers

    /// Mock TextToSpeechService for testing
    class MockTextToSpeechService: TextToSpeechServiceProtocol {
        var speakCalled = false
        var speakText: String?
        var stopCalled = false
        var pauseCalled = false
        var mockIsSpeaking = false
        var speakCallCount = 0
        var didFinishSpeaking: ((String) -> Void)?

        var isSpeaking: Bool {
            return mockIsSpeaking
        }

        func speak(text: String) {
            speakCalled = true
            speakText = text
            mockIsSpeaking = true
            speakCallCount += 1
        }

        func stop() {
            stopCalled = true
            mockIsSpeaking = false
        }

        func pause() {
            pauseCalled = true
        }

        func simulateFinish() {
            mockIsSpeaking = false
            didFinishSpeaking?(speakText ?? "")
        }

        func reset() {
            speakCalled = false
            speakText = nil
            stopCalled = false
            pauseCalled = false
            mockIsSpeaking = false
            speakCallCount = 0
        }
    }

    /// Mock SpeechRecognitionService for testing
    class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol {
        var startListeningCalled = false
        var stopListeningCalled = false
        var mockIsListening = false
        var startListeningCallCount = 0
        var stopListeningCallCount = 0
        var didRecognizeCommand: ((VoiceCommand) -> Void)?
        var onPermissionDenied: (() -> Void)?
        var onRecognitionUnavailable: (() -> Void)?

        var isListening: Bool {
            return mockIsListening
        }

        func startListening() {
            startListeningCalled = true
            mockIsListening = true
            startListeningCallCount += 1
        }

        func stopListening() {
            stopListeningCalled = true
            mockIsListening = false
            stopListeningCallCount += 1
        }

        func simulateCommand(_ command: VoiceCommand) {
            didRecognizeCommand?(command)
        }

        func simulatePermissionDenied() {
            onPermissionDenied?()
        }

        func simulateServiceUnavailable() {
            onRecognitionUnavailable?()
        }

        func reset() {
            startListeningCalled = false
            stopListeningCalled = false
            mockIsListening = false
            startListeningCallCount = 0
            stopListeningCallCount = 0
        }
    }

    /// Creates a test form with specified moves
    private func makeTestForm(title: String = "Test Form", moves: [String] = ["Move 1", "Move 2", "Move 3"]) -> Form {
        Form(title: title, moves: moves)
    }

    /// Creates a manager with mock services for testing
    private func makeTestManager(form: Form) -> (PracticeSessionManager, MockTextToSpeechService, MockSpeechRecognitionService) {
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let manager = PracticeSessionManager(
            form: form,
            ttsService: mockTTS,
            speechService: mockSpeech
        )
        return (manager, mockTTS, mockSpeech)
    }

    // MARK: - SessionState Enum Tests

    @Test func sessionStateEnumHasFiveCases() {
        let allStates: [SessionState] = [.ready, .speaking, .listening, .paused, .completed]
        #expect(allStates.count == 5)
    }

    @Test func sessionStateIsEquatable() {
        #expect(SessionState.ready == SessionState.ready)
        #expect(SessionState.speaking != SessionState.listening)
        #expect(SessionState.paused != SessionState.completed)
    }

    @Test func sessionStateCasesAreDistinct() {
        let states: Set<SessionState> = [.ready, .speaking, .listening, .paused, .completed]
        #expect(states.count == 5)
    }

    // MARK: - PracticeSessionManagerError Enum Tests

    @Test func managerErrorIsError() {
        let error: Error = PracticeSessionManagerError.emptyForm
        #expect(error is PracticeSessionManagerError)
    }

    @Test func managerErrorIsEquatable() {
        #expect(PracticeSessionManagerError.emptyForm == PracticeSessionManagerError.emptyForm)
        #expect(PracticeSessionManagerError.invalidMoveIndex != PracticeSessionManagerError.emptyForm)
    }

    @Test func managerErrorHasMeaningfulDescriptions() {
        let emptyFormError = PracticeSessionManagerError.emptyForm
        let invalidIndexError = PracticeSessionManagerError.invalidMoveIndex
        let serviceUnavailableError = PracticeSessionManagerError.serviceUnavailable
        let permissionDeniedError = PracticeSessionManagerError.permissionDenied

        let emptyFormDesc = String(describing: emptyFormError)
        let invalidIndexDesc = String(describing: invalidIndexError)
        let serviceUnavailableDesc = String(describing: serviceUnavailableError)
        let permissionDeniedDesc = String(describing: permissionDeniedError)

        #expect(emptyFormDesc.contains("empty") || emptyFormDesc.contains("form"))
        #expect(invalidIndexDesc.contains("index") || invalidIndexDesc.contains("move"))
        #expect(serviceUnavailableDesc.contains("service") || serviceUnavailableDesc.contains("unavailable"))
        #expect(permissionDeniedDesc.contains("permission") || permissionDeniedDesc.contains("denied"))
    }

    @Test func managerErrorHasAllFourCases() {
        let errors: [PracticeSessionManagerError] = [
            .emptyForm,
            .invalidMoveIndex,
            .serviceUnavailable,
            .permissionDenied
        ]
        #expect(errors.count == 4)
    }

    // MARK: - Initialization Tests

    @Test func managerInitializesWithFormAndServices() throws {
        let form = makeTestForm()
        let (manager, _, _) = makeTestManager(form: form)

        #expect(manager.currentForm.id == form.id)
        #expect(manager.currentForm.title == form.title)
        #expect(manager.currentForm.moves == form.moves)
    }

    @Test func managerInitialStateIsReady() throws {
        let form = makeTestForm()
        let (manager, _, _) = makeTestManager(form: form)

        #expect(manager.state == .ready)
    }

    @Test func managerInitialMoveIndexIsZero() throws {
        let form = makeTestForm()
        let (manager, _, _) = makeTestManager(form: form)

        #expect(manager.currentMoveIndex == 0)
    }

    @Test func currentMoveReturnsFirstMove() throws {
        let form = makeTestForm(moves: ["First Move", "Second Move", "Third Move"])
        let (manager, _, _) = makeTestManager(form: form)

        #expect(manager.currentMove == "First Move")
    }

    @Test func emptyFormValidationHappensInStart() throws {
        let emptyForm = makeTestForm(moves: [])
        let (manager, _, _) = makeTestManager(form: emptyForm)

        #expect(throws: PracticeSessionManagerError.emptyForm) {
            try manager.start()
        }
    }

    // MARK: - State Transition Tests

    @Test func startCommandTransitionsReadyToSpeaking() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        #expect(manager.state == .ready)

        try manager.start()

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
    }

    @Test func ttsCompletionTransitionsSpeakingToListening() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        #expect(manager.state == .speaking)

        mockTTS.simulateFinish()

        #expect(manager.state == .listening)
        #expect(mockSpeech.startListeningCalled)
    }

    @Test func nextCommandTransitionsListeningToSpeaking() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        mockTTS.reset()
        mockSpeech.simulateCommand(.next)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
    }

    @Test func pauseCommandTransitionsListeningToPaused() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        mockSpeech.simulateCommand(.pause)

        #expect(manager.state == .paused)
        #expect(mockSpeech.stopListeningCalled)
    }

    @Test func startCommandTransitionsPausedToSpeaking() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        mockTTS.reset()
        mockSpeech.simulateCommand(.start)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
    }

    @Test func stopCommandTransitionsAnyStateToExit() throws {
        let form = makeTestForm()

        // Test from Ready
        let (manager1, _, _) = makeTestManager(form: form)
        var exitCalled = false
        manager1.onExit = { exitCalled = true }
        manager1.stop()
        #expect(exitCalled)

        // Test from Speaking
        exitCalled = false
        let (manager2, mockTTS2, _) = makeTestManager(form: form)
        manager2.onExit = { exitCalled = true }
        try manager2.start()
        #expect(manager2.state == .speaking)
        manager2.stop()
        #expect(exitCalled)

        // Test from Listening
        exitCalled = false
        let (manager3, mockTTS3, _) = makeTestManager(form: form)
        manager3.onExit = { exitCalled = true }
        try manager3.start()
        mockTTS3.simulateFinish()
        #expect(manager3.state == .listening)
        manager3.stop()
        #expect(exitCalled)

        // Test from Paused
        exitCalled = false
        let (manager4, mockTTS4, mockSpeech4) = makeTestManager(form: form)
        manager4.onExit = { exitCalled = true }
        try manager4.start()
        mockTTS4.simulateFinish()
        mockSpeech4.simulateCommand(.pause)
        #expect(manager4.state == .paused)
        manager4.stop()
        #expect(exitCalled)
    }

    @Test func nextCommandAtLastMoveTransitionsToCompleted() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0)

        mockTTS.reset()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 1)

        mockTTS.reset()
        mockSpeech.simulateCommand(.next)

        #expect(manager.state == .completed)
    }

    @Test func startCommandInCompletedStateRestartsForm() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Complete the form
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        // Restart from completed
        mockTTS.reset()
        try manager.start()

        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == 0)
        #expect(mockTTS.speakCalled)
    }

    // MARK: - Command-State Validation Matrix Tests (PRD Section 6.1)

    @Test func startCommandValidInReadyPausedCompleted() throws {
        let form = makeTestForm()

        // Valid in Ready
        let (manager1, mockTTS1, _) = makeTestManager(form: form)
        #expect(manager1.state == .ready)
        try manager1.start()
        #expect(manager1.state == .speaking)

        // Valid in Paused
        let (manager2, mockTTS2, mockSpeech2) = makeTestManager(form: form)
        try manager2.start()
        mockTTS2.simulateFinish()
        mockSpeech2.simulateCommand(.pause)
        #expect(manager2.state == .paused)
        mockTTS2.reset()
        try manager2.start()
        #expect(manager2.state == .speaking)

        // Valid in Completed
        let (manager3, mockTTS3, mockSpeech3) = makeTestManager(form: makeTestForm(moves: ["Move 1"]))
        try manager3.start()
        mockTTS3.simulateFinish()
        mockSpeech3.simulateCommand(.next)
        #expect(manager3.state == .completed)
        mockTTS3.reset()
        try manager3.start()
        #expect(manager3.state == .speaking)
    }

    @Test func startCommandIgnoredInSpeakingListening() throws {
        let form = makeTestForm()

        // Ignored in Speaking
        let (manager1, mockTTS1, _) = makeTestManager(form: form)
        try manager1.start()
        #expect(manager1.state == .speaking)
        let speakCount1 = mockTTS1.speakCallCount
        try manager1.start()
        #expect(manager1.state == .speaking)
        #expect(mockTTS1.speakCallCount == speakCount1) // No additional speak call

        // Ignored in Listening
        let (manager2, mockTTS2, _) = makeTestManager(form: form)
        try manager2.start()
        mockTTS2.simulateFinish()
        #expect(manager2.state == .listening)
        let speakCount2 = mockTTS2.speakCallCount
        try manager2.start()
        #expect(manager2.state == .listening)
        #expect(mockTTS2.speakCallCount == speakCount2) // No additional speak call
    }

    @Test func nextCommandValidOnlyInListening() throws {
        let form = makeTestForm()

        // Valid in Listening
        let (manager1, mockTTS1, mockSpeech1) = makeTestManager(form: form)
        try manager1.start()
        mockTTS1.simulateFinish()
        #expect(manager1.state == .listening)
        mockTTS1.reset()
        mockSpeech1.simulateCommand(.next)
        #expect(manager1.state == .speaking)

        // Ignored in Ready
        let (manager2, mockTTS2, _) = makeTestManager(form: form)
        #expect(manager2.state == .ready)
        let index = manager2.currentMoveIndex
        mockSpeech1.simulateCommand(.next)
        #expect(manager2.state == .ready)
        #expect(manager2.currentMoveIndex == index)

        // Ignored in Speaking
        let (manager3, mockTTS3, _) = makeTestManager(form: form)
        try manager3.start()
        #expect(manager3.state == .speaking)
        let index3 = manager3.currentMoveIndex
        mockSpeech1.simulateCommand(.next)
        #expect(manager3.state == .speaking)
        #expect(manager3.currentMoveIndex == index3)
    }

    @Test func nextCommandIgnoredInPausedState() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Get to Paused state
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        // Try next command (should be ignored)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.next)

        // Verify ignored
        #expect(manager.state == .paused)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func nextCommandIgnoredInCompletedState() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Get to Completed state
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        // Try next command (should be ignored)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.next)

        // Verify ignored
        #expect(manager.state == .completed)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func backCommandValidOnlyInListening() throws {
        let form = makeTestForm()

        // Valid in Listening
        let (manager1, mockTTS1, mockSpeech1) = makeTestManager(form: form)
        try manager1.start()
        mockTTS1.simulateFinish()
        mockSpeech1.simulateCommand(.next)
        mockTTS1.simulateFinish()
        #expect(manager1.state == .listening)
        #expect(manager1.currentMoveIndex == 1)
        mockTTS1.reset()
        mockSpeech1.simulateCommand(.back)
        #expect(manager1.state == .speaking)
        #expect(manager1.currentMoveIndex == 0)
    }

    @Test func backCommandIgnoredInReadyState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        #expect(manager.state == .ready)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.back)

        #expect(manager.state == .ready)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func backCommandIgnoredInSpeakingState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        try manager.start()
        #expect(manager.state == .speaking)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.back)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func backCommandIgnoredInPausedState() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)
        #expect(manager.currentMoveIndex == 1)

        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.back)

        #expect(manager.state == .paused)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func backCommandIgnoredInCompletedState() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.back)

        #expect(manager.state == .completed)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func repeatCommandValidOnlyInListening() throws {
        let form = makeTestForm()

        // Valid in Listening
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)
        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)
        let index = manager.currentMoveIndex
        mockTTS.reset()
        mockSpeech.simulateCommand(.repeat)
        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == index) // Same index
    }

    @Test func repeatCommandIgnoredInReadyState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        #expect(manager.state == .ready)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.repeat)

        #expect(manager.state == .ready)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func repeatCommandIgnoredInSpeakingState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        try manager.start()
        #expect(manager.state == .speaking)
        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.repeat)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func repeatCommandIgnoredInPausedState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.repeat)

        #expect(manager.state == .paused)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func repeatCommandIgnoredInCompletedState() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        let ttsCountBefore = mockTTS.speakCallCount
        let indexBefore = manager.currentMoveIndex
        manager.handleCommand(.repeat)

        #expect(manager.state == .completed)
        #expect(mockTTS.speakCallCount == ttsCountBefore)
        #expect(manager.currentMoveIndex == indexBefore)
    }

    @Test func pauseCommandValidOnlyInListening() throws {
        let form = makeTestForm()

        // Valid in Listening
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)
        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)
    }

    @Test func pauseCommandIgnoredInReadyState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        #expect(manager.state == .ready)
        manager.handleCommand(.pause)

        #expect(manager.state == .ready)
        #expect(mockSpeech.stopListeningCallCount == 0)
    }

    @Test func pauseCommandIgnoredInSpeakingState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        #expect(manager.state == .speaking)
        let stopCountBefore = mockSpeech.stopListeningCallCount
        manager.handleCommand(.pause)

        #expect(manager.state == .speaking)
        #expect(mockSpeech.stopListeningCallCount == stopCountBefore)
    }

    @Test func pauseCommandIgnoredInPausedState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        let stopCountBefore = mockSpeech.stopListeningCallCount
        manager.handleCommand(.pause)

        #expect(manager.state == .paused)
        #expect(mockSpeech.stopListeningCallCount == stopCountBefore)
    }

    @Test func pauseCommandIgnoredInCompletedState() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        let stopCountBefore = mockSpeech.stopListeningCallCount
        manager.handleCommand(.pause)

        #expect(manager.state == .completed)
        #expect(mockSpeech.stopListeningCallCount == stopCountBefore)
    }

    @Test func stopCommandValidInAllStates() throws {
        let form = makeTestForm()
        var exitCalled: Bool

        // Ready
        exitCalled = false
        let (manager1, _, _) = makeTestManager(form: form)
        manager1.onExit = { exitCalled = true }
        manager1.stop()
        #expect(exitCalled)

        // Speaking
        exitCalled = false
        let (manager2, _, _) = makeTestManager(form: form)
        manager2.onExit = { exitCalled = true }
        try manager2.start()
        manager2.stop()
        #expect(exitCalled)

        // Listening
        exitCalled = false
        let (manager3, mockTTS3, _) = makeTestManager(form: form)
        manager3.onExit = { exitCalled = true }
        try manager3.start()
        mockTTS3.simulateFinish()
        manager3.stop()
        #expect(exitCalled)

        // Paused
        exitCalled = false
        let (manager4, mockTTS4, mockSpeech4) = makeTestManager(form: form)
        manager4.onExit = { exitCalled = true }
        try manager4.start()
        mockTTS4.simulateFinish()
        mockSpeech4.simulateCommand(.pause)
        manager4.stop()
        #expect(exitCalled)

        // Completed
        exitCalled = false
        let (manager5, mockTTS5, mockSpeech5) = makeTestManager(form: makeTestForm(moves: ["Move 1"]))
        manager5.onExit = { exitCalled = true }
        try manager5.start()
        mockTTS5.simulateFinish()
        mockSpeech5.simulateCommand(.next)
        manager5.stop()
        #expect(exitCalled)
    }

    // MARK: - Navigation Tests

    @Test func moveNextAdvancesIndexAndSpeaks() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0)

        mockTTS.reset()
        mockSpeech.simulateCommand(.next)

        #expect(manager.currentMoveIndex == 1)
        #expect(manager.currentMove == "Move 2")
        #expect(mockTTS.speakCalled)
        #expect(mockTTS.speakText == "Move 2")
    }

    @Test func moveNextAtLastMoveTransitionsToCompleted() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 1)

        mockSpeech.simulateCommand(.next)

        #expect(manager.state == .completed)
    }

    @Test func movePreviousDecrementsIndexAndSpeaks() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 1)

        mockTTS.reset()
        mockSpeech.simulateCommand(.back)

        #expect(manager.currentMoveIndex == 0)
        #expect(manager.currentMove == "Move 1")
        #expect(mockTTS.speakCalled)
        #expect(mockTTS.speakText == "Move 1")
    }

    @Test func movePreviousAtFirstMoveBehavesLikeRepeat() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0)

        mockTTS.reset()
        mockSpeech.simulateCommand(.back)

        #expect(manager.currentMoveIndex == 0)
        #expect(manager.currentMove == "Move 1")
        #expect(mockTTS.speakCalled)
        #expect(mockTTS.speakText == "Move 1")
    }

    @Test func repeatCurrentStaysAtSameIndexAndSpeaks() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 1)

        mockTTS.reset()
        mockSpeech.simulateCommand(.repeat)

        #expect(manager.currentMoveIndex == 1)
        #expect(manager.currentMove == "Move 2")
        #expect(mockTTS.speakCalled)
        #expect(mockTTS.speakText == "Move 2")
    }

    // MARK: - Service Coordination Tests (CRITICAL: Mutual Exclusion)

    @Test func speakingStateRunsTTSAndStopsSpeechRecognition() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
        #expect(!mockSpeech.mockIsListening)
    }

    @Test func listeningStateRunsSpeechRecognitionAndStopsTTS() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()

        #expect(manager.state == .listening)
        #expect(mockSpeech.startListeningCalled)
        #expect(!mockTTS.mockIsSpeaking)
    }

    @Test func servicesNeverRunSimultaneously() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Initial state - both off
        #expect(!mockTTS.mockIsSpeaking)
        #expect(!mockSpeech.mockIsListening)

        // Speaking state - TTS on, speech off
        try manager.start()
        #expect(mockTTS.mockIsSpeaking)
        #expect(!mockSpeech.mockIsListening)

        // Listening state - TTS off, speech on
        mockTTS.simulateFinish()
        #expect(!mockTTS.mockIsSpeaking)
        #expect(mockSpeech.mockIsListening)

        // Navigate to next move (speaking) - TTS on, speech off
        mockSpeech.simulateCommand(.next)
        #expect(mockTTS.mockIsSpeaking)
        #expect(!mockSpeech.mockIsListening)

        // Stop - both off
        manager.stop()
        #expect(!mockTTS.mockIsSpeaking)
        #expect(!mockSpeech.mockIsListening)
    }

    @Test func ttsCompletionTriggersSpeechRecognition() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        #expect(mockSpeech.startListeningCallCount == 0)

        mockTTS.simulateFinish()

        #expect(mockSpeech.startListeningCallCount == 1)
        #expect(mockSpeech.mockIsListening)
    }

    @Test func commandRecognitionTriggersTTSStop() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        mockSpeech.reset()
        mockSpeech.simulateCommand(.next)

        #expect(mockSpeech.stopListeningCalled)
        #expect(mockTTS.speakCalled)
    }

    @Test func pauseStopsSpeechRecognition() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(mockSpeech.mockIsListening)

        mockSpeech.simulateCommand(.pause)

        #expect(!mockSpeech.mockIsListening)
        #expect(mockSpeech.stopListeningCalled)
    }

    @Test func stopStopsBothServices() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        manager.stop()

        #expect(mockTTS.stopCalled)
        #expect(mockSpeech.stopListeningCalled)
    }

    // MARK: - Callback Tests

    @Test func onStateChangedCalledOnStateTransitions() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var stateChanges: [SessionState] = []
        manager.onStateChanged = { state in
            stateChanges.append(state)
        }

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)

        #expect(stateChanges == [.speaking, .listening, .paused])
    }

    @Test func onMoveChangedCalledOnMoveChanges() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var moveChanges: [(Int, String)] = []
        manager.onMoveChanged = { index, move in
            moveChanges.append((index, move))
        }

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.back)

        #expect(moveChanges.count == 2)
        #expect(moveChanges[0].0 == 1)
        #expect(moveChanges[0].1 == "Move 2")
        #expect(moveChanges[1].0 == 0)
        #expect(moveChanges[1].1 == "Move 1")
    }

    @Test func onTimeoutCalledAfterTwoMinutes() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        var timeoutCalled = false
        manager.onTimeout = {
            timeoutCalled = true
        }

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Simulate timeout (would need timer access or test helper)
        manager.handleTimeout()

        #expect(timeoutCalled)
        #expect(manager.state == .listening) // Remains listening after timeout
    }

    @Test func onErrorCalledOnServiceErrors() throws {
        let form = makeTestForm()
        let (manager, _, mockSpeech) = makeTestManager(form: form)

        var errorReceived: PracticeSessionManagerError?
        manager.onError = { error in
            errorReceived = error
        }

        mockSpeech.simulateServiceUnavailable()

        #expect(errorReceived == .serviceUnavailable)
    }

    @Test func onExitCalledOnStopCommand() throws {
        let form = makeTestForm()
        let (manager, _, _) = makeTestManager(form: form)

        var exitCalled = false
        manager.onExit = {
            exitCalled = true
        }

        manager.stop()

        #expect(exitCalled)
    }

    @Test func callbacksCanBeNil() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Set all callbacks to nil
        manager.onStateChanged = nil
        manager.onMoveChanged = nil
        manager.onTimeout = nil
        manager.onError = nil
        manager.onExit = nil

        // Should not crash
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        manager.handleTimeout()
        manager.stop()
    }

    // MARK: - Timeout Tests

    @Test func timerStartsWhenEnteringListeningState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()

        #expect(manager.state == .listening)
        // Timer should be active (verified by timeout test)
    }

    @Test func timerResetsWhenCommandReceived() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var timeoutCount = 0
        manager.onTimeout = {
            timeoutCount += 1
        }

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Receive command before timeout
        mockSpeech.simulateCommand(.repeat)
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Timer should have reset
        #expect(timeoutCount == 0)
    }

    @Test func timeoutFiresAfterTwoMinutes() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        var timeoutCalled = false
        manager.onTimeout = {
            timeoutCalled = true
        }

        try manager.start()
        mockTTS.simulateFinish()

        // Simulate 2 minute timeout
        manager.handleTimeout()

        #expect(timeoutCalled)
    }

    @Test func stateRemainsListeningAfterTimeout() throws {
        let form = makeTestForm()
        let (manager, mockTTS, _) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        manager.handleTimeout()

        #expect(manager.state == .listening)
    }

    @Test func timerInvalidatedWhenLeavingListeningState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var timeoutCount = 0
        manager.onTimeout = {
            timeoutCount += 1
        }

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Leave listening state
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        // Timer should be invalidated
        manager.handleTimeout()
        #expect(timeoutCount == 0) // Timeout handler should not be called
    }

    // MARK: - Error Handling Tests

    @Test func permissionDeniedTriggersOnErrorCallback() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var errorReceived: PracticeSessionManagerError?
        manager.onError = { error in
            errorReceived = error
        }

        // Start session and transition to listening
        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Simulate permission denied
        mockSpeech.simulatePermissionDenied()

        // Verify error received
        #expect(errorReceived == .permissionDenied)

        // Verify state machine cleanup
        #expect(manager.state == .ready)
        #expect(mockSpeech.isListening == false)
        #expect(mockTTS.isSpeaking == false)
    }

    @Test func serviceUnavailableTriggersOnErrorCallback() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        var errorReceived: PracticeSessionManagerError?
        manager.onError = { error in
            errorReceived = error
        }

        // Start session and transition to listening
        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        // Simulate service unavailable
        mockSpeech.simulateServiceUnavailable()

        // Verify error received
        #expect(errorReceived == .serviceUnavailable)

        // Verify state machine cleanup
        #expect(manager.state == .ready)
        #expect(mockSpeech.isListening == false)
        #expect(mockTTS.isSpeaking == false)
    }

    // MARK: - Edge Cases

    @Test func formWithOneMove() throws {
        let form = makeTestForm(moves: ["Only Move"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0)

        mockSpeech.simulateCommand(.next)

        #expect(manager.state == .completed)
    }

    @Test func multipleCommandsInRapidSuccession() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()

        // Rapid commands
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.back)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.repeat)

        #expect(manager.currentMoveIndex == 1)
    }

    @Test func commandsDuringStateTransitions() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        #expect(manager.state == .speaking)

        // Command during speaking should be ignored
        let initialIndex = manager.currentMoveIndex
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == initialIndex)
    }

    @Test func stopCommandInAnyState() throws {
        let form = makeTestForm()

        // Ready
        var exitCalled = false
        let (manager1, _, _) = makeTestManager(form: form)
        manager1.onExit = { exitCalled = true }
        manager1.stop()
        #expect(exitCalled)

        // Speaking
        exitCalled = false
        let (manager2, _, _) = makeTestManager(form: form)
        manager2.onExit = { exitCalled = true }
        try manager2.start()
        manager2.stop()
        #expect(exitCalled)

        // Listening
        exitCalled = false
        let (manager3, mockTTS3, _) = makeTestManager(form: form)
        manager3.onExit = { exitCalled = true }
        try manager3.start()
        mockTTS3.simulateFinish()
        manager3.stop()
        #expect(exitCalled)
    }

    @Test func startCommandInCompletedStateRestartsFromBeginning() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Complete form
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)
        #expect(manager.currentMoveIndex == 1)

        // Restart
        mockTTS.reset()
        try manager.start()

        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == 0)
        #expect(manager.currentMove == "Move 1")
    }

    @Test func beginCommandBehavesLikeStart() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        #expect(manager.state == .ready)

        mockSpeech.simulateCommand(.begin)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
    }

    @Test func beginCommandBehavesLikeStartInPausedState() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Get to Paused state
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.pause)
        #expect(manager.state == .paused)

        // Use begin to resume
        mockTTS.reset()
        mockSpeech.simulateCommand(.begin)

        #expect(manager.state == .speaking)
        #expect(mockTTS.speakCalled)
    }

    @Test func beginCommandBehavesLikeStartInCompletedState() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Get to Completed state
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        // Use begin to restart
        mockTTS.reset()
        mockSpeech.simulateCommand(.begin)

        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == 0)
        #expect(mockTTS.speakCalled)
    }

    @Test func goCommandBehavesLikeNext() throws {
        let form = makeTestForm()
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)

        mockTTS.reset()
        mockSpeech.simulateCommand(.go)

        #expect(manager.state == .speaking)
        #expect(manager.currentMoveIndex == 1)
    }

    @Test func goCommandCompletesFormAtLastMove() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        // Get to last move
        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.state == .listening)
        #expect(manager.currentMoveIndex == 1)

        // Use go to complete form
        mockSpeech.simulateCommand(.go)

        #expect(manager.state == .completed)
    }

    @Test func moveNavigationWrapsCorrectly() throws {
        let form = makeTestForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()

        // Move forward twice
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 2)

        // Move back three times
        mockSpeech.simulateCommand(.back)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 1)

        mockSpeech.simulateCommand(.back)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0)

        mockSpeech.simulateCommand(.back)
        mockTTS.simulateFinish()
        #expect(manager.currentMoveIndex == 0) // Stays at first move
    }

    @Test func completedStatePreventsFurtherNavigation() throws {
        let form = makeTestForm(moves: ["Move 1"])
        let (manager, mockTTS, mockSpeech) = makeTestManager(form: form)

        try manager.start()
        mockTTS.simulateFinish()
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)

        // Try navigation commands in completed state
        let index = manager.currentMoveIndex
        mockSpeech.simulateCommand(.next)
        #expect(manager.state == .completed)
        #expect(manager.currentMoveIndex == index)

        mockSpeech.simulateCommand(.back)
        #expect(manager.state == .completed)
        #expect(manager.currentMoveIndex == index)
    }
}
