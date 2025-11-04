//
//  PracticeViewModelTests.swift
//  katadoshiTests
//
//  Created by Claude Code on 11/3/25.
//

import Testing
import Foundation
@testable import katadoshi

/// Unit tests for PracticeViewModel business logic
///
/// Tests the PracticeViewModel according to PRD Section 9.3 (Practice View)
/// and Groucho's technical plan for the @Observable wrapper pattern.
///
/// **Architectural Responsibility:**
/// PracticeViewModel wraps PracticeSessionManager with @Observable pattern,
/// bridges callback-based manager to SwiftUI reactive updates, and manages
/// FormStore.lastPracticed updates.
///
/// **Test Coverage:**
/// 1. Initialization with form and services
/// 2. Manager callback → ViewModel state updates
///    - onStateChanged updates sessionState and clears timeout
///    - onMoveChanged updates index and text
///    - onTimeout sets showTimeout flag
///    - onError sets error property
///    - onExit sets shouldDismiss flag
/// 3. ViewModel methods
///    - startSession() calls manager.start() and updates lastPracticed
///    - stopSession() calls manager.stop()
///    - handleManualStart() for manual start button
///    - handleManualStop() for manual stop button
/// 4. Error propagation from manager
/// 5. Permission handling logic
/// 6. Edge cases and integration scenarios
@MainActor
struct PracticeViewModelTests {

    // MARK: - Test Helpers

    /// Mock PracticeSessionManager for testing
    class MockPracticeSessionManager: PracticeSessionManagerProtocol {
        var currentForm: Form
        var currentMoveIndex: Int = 0
        var state: SessionState = .ready
        var currentMove: String {
            guard currentMoveIndex < currentForm.moves.count else { return "" }
            return currentForm.moves[currentMoveIndex]
        }

        var onStateChanged: ((SessionState) -> Void)?
        var onMoveChanged: ((Int, String) -> Void)?
        var onTimeout: (() -> Void)?
        var onError: ((PracticeSessionManagerError) -> Void)?
        var onExit: (() -> Void)?

        var startCalled = false
        var stopCalled = false
        var handleCommandCalled = false
        var pauseCalled = false
        var lastCommand: VoiceCommand?
        var shouldThrowOnStart: PracticeSessionManagerError?

        init(form: Form) {
            self.currentForm = form
        }

        func start() throws {
            if let error = shouldThrowOnStart {
                throw error
            }
            startCalled = true
        }

        func handleCommand(_ command: VoiceCommand) {
            handleCommandCalled = true
            lastCommand = command
        }

        func stop() {
            stopCalled = true
        }

        func pause() {
            pauseCalled = true
        }

        // Test helper methods to simulate manager behavior
        func simulateStateChange(_ newState: SessionState) {
            state = newState
            onStateChanged?(newState)
        }

        func simulateMoveChange(index: Int, text: String) {
            currentMoveIndex = index
            onMoveChanged?(index, text)
        }

        func simulateTimeout() {
            onTimeout?()
        }

        func simulateError(_ error: PracticeSessionManagerError) {
            onError?(error)
        }

        func simulateExit() {
            onExit?()
        }

        func reset() {
            startCalled = false
            stopCalled = false
            handleCommandCalled = false
            pauseCalled = false
            lastCommand = nil
            shouldThrowOnStart = nil
        }
    }

    /// Creates a test FormStore with fresh UserDefaults suite
    private func makeTestStore(suiteName: String = UUID().uuidString) -> FormStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return FormStore(userDefaults: defaults)
    }

    /// Creates a valid test form
    private func makeValidForm(
        title: String = "Test Form",
        moves: [String] = ["Move 1", "Move 2", "Move 3"],
        lastPracticed: Date = Date(timeIntervalSince1970: 0)
    ) -> Form {
        Form(title: title, moves: moves, lastPracticed: lastPracticed)
    }

    /// Creates a PracticeViewModel with mock manager for testing
    private func makeTestViewModel(
        form: Form,
        formStore: FormStore? = nil
    ) -> (PracticeViewModel, MockPracticeSessionManager, FormStore) {
        let store = formStore ?? makeTestStore()
        let mockManager = MockPracticeSessionManager(form: form)

        // Create ViewModel using the mock manager
        // Note: PracticeViewModel will need an initializer that accepts a manager
        let viewModel = PracticeViewModel(
            form: form,
            formStore: store,
            sessionManager: mockManager
        )

        return (viewModel, mockManager, store)
    }

    // MARK: - Initialization Tests

    @Test func viewModelInitializesWithFormAndServices() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(mockManager.currentForm.id == form.id)
        #expect(viewModel.sessionState == .ready)
        #expect(viewModel.currentMoveIndex == 0)
        #expect(viewModel.totalMoves == 3)
        #expect(!viewModel.showTimeout)
        #expect(viewModel.error == nil)
        #expect(!viewModel.shouldDismiss)
    }

    @Test func viewModelInitializesWithCorrectMoveText() throws {
        let form = makeValidForm(moves: ["First Move", "Second Move", "Third Move"])
        let (viewModel, _, _) = makeTestViewModel(form: form)

        #expect(viewModel.currentMoveText == "First Move")
    }

    @Test func viewModelInitializesTotalMovesCount() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3", "Move 4", "Move 5"])
        let (viewModel, _, _) = makeTestViewModel(form: form)

        #expect(viewModel.totalMoves == 5)
    }

    @Test func viewModelRegistersCallbacksWithManager() throws {
        let form = makeValidForm()
        let (_, mockManager, _) = makeTestViewModel(form: form)

        // Verify that manager callbacks are registered (not nil)
        // This ensures the reactive update mechanism works
        #expect(mockManager.onStateChanged != nil, "onStateChanged callback should be registered")
        #expect(mockManager.onMoveChanged != nil, "onMoveChanged callback should be registered")
        #expect(mockManager.onTimeout != nil, "onTimeout callback should be registered")
        #expect(mockManager.onError != nil, "onError callback should be registered")
        #expect(mockManager.onExit != nil, "onExit callback should be registered")
    }

    // MARK: - onStateChanged Callback Tests

    @Test func onStateChangedUpdatesSessionState() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(viewModel.sessionState == .ready)

        mockManager.simulateStateChange(.speaking)
        #expect(viewModel.sessionState == .speaking)

        mockManager.simulateStateChange(.listening)
        #expect(viewModel.sessionState == .listening)

        mockManager.simulateStateChange(.paused)
        #expect(viewModel.sessionState == .paused)

        mockManager.simulateStateChange(.completed)
        #expect(viewModel.sessionState == .completed)
    }

    @Test func onStateChangedClearsTimeoutFlag() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Set timeout flag
        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)

        // State change should clear timeout
        mockManager.simulateStateChange(.speaking)
        #expect(!viewModel.showTimeout)
    }

    @Test func onStateChangedFromListeningToSpeakingClearsTimeout() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateStateChange(.listening)
        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)

        mockManager.simulateStateChange(.speaking)
        #expect(!viewModel.showTimeout)
    }

    // MARK: - onMoveChanged Callback Tests

    @Test func onMoveChangedUpdatesIndexAndText() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(viewModel.currentMoveIndex == 0)
        #expect(viewModel.currentMoveText == "Move 1")

        mockManager.simulateMoveChange(index: 1, text: "Move 2")

        #expect(viewModel.currentMoveIndex == 1)
        #expect(viewModel.currentMoveText == "Move 2")
    }

    @Test func onMoveChangedUpdatesToLastMove() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateMoveChange(index: 2, text: "Move 3")

        #expect(viewModel.currentMoveIndex == 2)
        #expect(viewModel.currentMoveText == "Move 3")
    }

    @Test func onMoveChangedUpdatesBackToFirstMove() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateMoveChange(index: 1, text: "Move 2")
        #expect(viewModel.currentMoveIndex == 1)

        mockManager.simulateMoveChange(index: 0, text: "Move 1")
        #expect(viewModel.currentMoveIndex == 0)
        #expect(viewModel.currentMoveText == "Move 1")
    }

    // MARK: - onTimeout Callback Tests

    @Test func onTimeoutSetsShowTimeoutFlag() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!viewModel.showTimeout)

        mockManager.simulateTimeout()

        #expect(viewModel.showTimeout)
    }

    @Test func onTimeoutFlagPersistsUntilStateChange() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)

        // Flag should persist
        #expect(viewModel.showTimeout)

        // Cleared by state change
        mockManager.simulateStateChange(.speaking)
        #expect(!viewModel.showTimeout)
    }

    // MARK: - onError Callback Tests

    @Test func onErrorSetsErrorProperty() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(viewModel.error == nil)

        mockManager.simulateError(.permissionDenied)

        #expect(viewModel.error == .permissionDenied)
    }

    @Test func onErrorSetsServiceUnavailable() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.serviceUnavailable)

        #expect(viewModel.error == .serviceUnavailable)
    }

    @Test func onErrorCanUpdateMultipleTimes() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.permissionDenied)
        #expect(viewModel.error == .permissionDenied)

        mockManager.simulateError(.serviceUnavailable)
        #expect(viewModel.error == .serviceUnavailable)
    }

    // MARK: - onExit Callback Tests

    @Test func onExitSetsShouldDismissFlag() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!viewModel.shouldDismiss)

        mockManager.simulateExit()

        #expect(viewModel.shouldDismiss)
    }

    @Test func onExitFlagPersists() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateExit()
        #expect(viewModel.shouldDismiss)

        // Flag should remain set
        #expect(viewModel.shouldDismiss)
    }

    // MARK: - startSession() Method Tests

    @Test func startSessionCallsManagerStart() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!mockManager.startCalled)

        try viewModel.startSession()

        #expect(mockManager.startCalled)
    }

    @Test func startSessionUpdatesLastPracticed() throws {
        let form = makeValidForm(lastPracticed: Date(timeIntervalSince1970: 0))
        let store = makeTestStore()
        try store.saveForm(form: form)

        let (viewModel, _, _) = makeTestViewModel(form: form, formStore: store)

        let beforeDate = Date()
        try viewModel.startSession()
        let afterDate = Date()

        // Reload form from store
        let updatedForm = store.forms.first { $0.id == form.id }
        #expect(updatedForm != nil)
        #expect(updatedForm!.lastPracticed >= beforeDate)
        #expect(updatedForm!.lastPracticed <= afterDate)
    }

    @Test func startSessionThrowsErrorFromManager() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.shouldThrowOnStart = .emptyForm

        #expect(throws: PracticeSessionManagerError.emptyForm) {
            try viewModel.startSession()
        }
    }

    // MARK: - stopSession() Method Tests

    @Test func stopSessionCallsManagerStop() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!mockManager.stopCalled)

        viewModel.stopSession()

        #expect(mockManager.stopCalled)
    }

    @Test func stopSessionCanBeCalledMultipleTimes() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        viewModel.stopSession()
        #expect(mockManager.stopCalled)

        mockManager.reset()

        viewModel.stopSession()
        #expect(mockManager.stopCalled)
    }

    // MARK: - handleManualStart() Method Tests

    @Test func handleManualStartCallsStartSession() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!mockManager.startCalled)

        viewModel.handleManualStart()

        #expect(mockManager.startCalled)
    }

    @Test func handleManualStartCapturesErrors() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.shouldThrowOnStart = .permissionDenied

        viewModel.handleManualStart()

        // Error should be captured in viewModel.error
        #expect(viewModel.error == .permissionDenied)
    }

    // MARK: - handleManualStop() Method Tests

    @Test func handleManualStopCallsStopSession() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        #expect(!mockManager.stopCalled)

        viewModel.handleManualStop()

        #expect(mockManager.stopCalled)
    }

    // MARK: - Lifecycle Management Tests

    @Test func viewModelHandlesPermissionDeniedError() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Simulate permission denied error from manager
        mockManager.simulateError(.permissionDenied)

        // Error should be captured in viewModel
        #expect(viewModel.error == .permissionDenied)
    }

    @Test func viewModelStopsSessionOnDismissal() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Start a session
        try viewModel.startSession()
        mockManager.simulateStateChange(.speaking)
        #expect(viewModel.sessionState == .speaking)

        // Call stopSession (simulating view dismissal)
        viewModel.stopSession()

        #expect(mockManager.stopCalled, "Session should be stopped when view is dismissed")
    }

    @Test func viewModelCleansUpServicesOnCleanup() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Start a session
        try viewModel.startSession()
        mockManager.simulateStateChange(.listening)

        // Cleanup should stop the session
        viewModel.stopSession()

        #expect(mockManager.stopCalled, "Cleanup should stop active session")
    }

    // MARK: - State Synchronization Tests

    @Test func viewModelStateMatchesManagerState() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        let states: [SessionState] = [.ready, .speaking, .listening, .paused, .completed]

        for state in states {
            mockManager.simulateStateChange(state)
            #expect(viewModel.sessionState == state)
        }
    }

    @Test func viewModelMoveDataMatchesManagerData() throws {
        let form = makeValidForm(moves: ["A", "B", "C", "D", "E"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        for i in 0..<form.moves.count {
            mockManager.simulateMoveChange(index: i, text: form.moves[i])
            #expect(viewModel.currentMoveIndex == i)
            #expect(viewModel.currentMoveText == form.moves[i])
        }
    }

    // MARK: - Error Propagation Tests

    @Test func permissionDeniedErrorPropagates() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.permissionDenied)

        #expect(viewModel.error == .permissionDenied)
    }

    @Test func serviceUnavailableErrorPropagates() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.serviceUnavailable)

        #expect(viewModel.error == .serviceUnavailable)
    }

    @Test func emptyFormErrorPropagates() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.shouldThrowOnStart = .emptyForm

        viewModel.handleManualStart()

        #expect(viewModel.error == .emptyForm)
    }

    @Test func invalidMoveIndexErrorPropagates() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.invalidMoveIndex)

        #expect(viewModel.error == .invalidMoveIndex)
    }

    // MARK: - Edge Cases

    @Test func singleMoveForm() throws {
        let form = makeValidForm(moves: ["Only Move"])
        let (viewModel, _, _) = makeTestViewModel(form: form)

        #expect(viewModel.totalMoves == 1)
        #expect(viewModel.currentMoveText == "Only Move")
        #expect(viewModel.currentMoveIndex == 0)
    }

    @Test func longFormWithManyMoves() throws {
        let manyMoves = (1...100).map { "Move \($0)" }
        let form = makeValidForm(moves: manyMoves)
        let (viewModel, _, _) = makeTestViewModel(form: form)

        #expect(viewModel.totalMoves == 100)
        #expect(viewModel.currentMoveText == "Move 1")
    }

    @Test func rapidStateChanges() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)
        mockManager.simulateStateChange(.paused)
        mockManager.simulateStateChange(.listening)
        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.completed)

        #expect(viewModel.sessionState == .completed)
    }

    @Test func rapidMoveChanges() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateMoveChange(index: 0, text: "Move 1")
        mockManager.simulateMoveChange(index: 1, text: "Move 2")
        mockManager.simulateMoveChange(index: 2, text: "Move 3")
        mockManager.simulateMoveChange(index: 1, text: "Move 2")
        mockManager.simulateMoveChange(index: 0, text: "Move 1")

        #expect(viewModel.currentMoveIndex == 0)
        #expect(viewModel.currentMoveText == "Move 1")
    }

    @Test func timeoutDuringDifferentStates() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Timeout in ready state (shouldn't happen but test resilience)
        mockManager.simulateStateChange(.ready)
        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)

        // Clear timeout
        mockManager.simulateStateChange(.speaking)
        #expect(!viewModel.showTimeout)

        // Timeout in listening state (expected)
        mockManager.simulateStateChange(.listening)
        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)
    }

    @Test func multipleErrorsInSequence() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        mockManager.simulateError(.permissionDenied)
        #expect(viewModel.error == .permissionDenied)

        mockManager.simulateError(.serviceUnavailable)
        #expect(viewModel.error == .serviceUnavailable)

        mockManager.simulateError(.emptyForm)
        #expect(viewModel.error == .emptyForm)

        mockManager.simulateError(.invalidMoveIndex)
        #expect(viewModel.error == .invalidMoveIndex)
    }

    // MARK: - Integration Tests

    @Test func fullSessionLifecycle() throws {
        let form = makeValidForm()
        let store = makeTestStore()
        try store.saveForm(form: form)

        let (viewModel, mockManager, _) = makeTestViewModel(form: form, formStore: store)

        // Start session
        try viewModel.startSession()
        #expect(mockManager.startCalled)

        // Simulate state transitions
        mockManager.simulateStateChange(.speaking)
        #expect(viewModel.sessionState == .speaking)

        mockManager.simulateStateChange(.listening)
        #expect(viewModel.sessionState == .listening)

        // Simulate move changes
        mockManager.simulateMoveChange(index: 1, text: "Move 2")
        #expect(viewModel.currentMoveIndex == 1)

        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)

        mockManager.simulateMoveChange(index: 2, text: "Move 3")
        #expect(viewModel.currentMoveIndex == 2)

        // Complete
        mockManager.simulateStateChange(.completed)
        #expect(viewModel.sessionState == .completed)

        // Stop
        viewModel.stopSession()
        #expect(mockManager.stopCalled)
    }

    @Test func errorRecoveryFlow() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Simulate error
        mockManager.simulateError(.permissionDenied)
        #expect(viewModel.error == .permissionDenied)

        // User dismisses error and tries again
        // ViewModel should be able to start again
        try viewModel.startSession()
        #expect(mockManager.startCalled)
    }

    @Test func pauseAndResumeFlow() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Start
        try viewModel.startSession()
        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)

        // Pause
        mockManager.simulateStateChange(.paused)
        #expect(viewModel.sessionState == .paused)

        // Resume
        try viewModel.startSession()
        mockManager.simulateStateChange(.speaking)
        #expect(viewModel.sessionState == .speaking)
    }

    @Test func timeoutRecoveryFlow() throws {
        let form = makeValidForm()
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Enter listening state
        mockManager.simulateStateChange(.listening)
        #expect(viewModel.sessionState == .listening)

        // Timeout occurs
        mockManager.simulateTimeout()
        #expect(viewModel.showTimeout)
        #expect(viewModel.sessionState == .listening)

        // User says "next" to continue
        mockManager.simulateStateChange(.speaking)
        #expect(!viewModel.showTimeout)
        #expect(viewModel.sessionState == .speaking)
    }

    @Test func stopFromAnyStateFlow() throws {
        let form = makeValidForm()

        // Stop from speaking
        let (viewModel1, mockManager1, _) = makeTestViewModel(form: form)
        mockManager1.simulateStateChange(.speaking)
        viewModel1.stopSession()
        #expect(mockManager1.stopCalled)

        // Stop from listening
        let (viewModel2, mockManager2, _) = makeTestViewModel(form: form)
        mockManager2.simulateStateChange(.listening)
        viewModel2.stopSession()
        #expect(mockManager2.stopCalled)

        // Stop from paused
        let (viewModel3, mockManager3, _) = makeTestViewModel(form: form)
        mockManager3.simulateStateChange(.paused)
        viewModel3.stopSession()
        #expect(mockManager3.stopCalled)

        // Stop from completed
        let (viewModel4, mockManager4, _) = makeTestViewModel(form: form)
        mockManager4.simulateStateChange(.completed)
        viewModel4.stopSession()
        #expect(mockManager4.stopCalled)
    }

    @Test func completedStateRestartResetsToFirstMove() throws {
        let form = makeValidForm(moves: ["Move 1", "Move 2", "Move 3"])
        let (viewModel, mockManager, _) = makeTestViewModel(form: form)

        // Start and progress through form to completed state
        try viewModel.startSession()
        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)

        mockManager.simulateMoveChange(index: 1, text: "Move 2")
        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)

        mockManager.simulateMoveChange(index: 2, text: "Move 3")
        mockManager.simulateStateChange(.speaking)
        mockManager.simulateStateChange(.listening)

        // Complete the form
        mockManager.simulateStateChange(.completed)
        #expect(viewModel.sessionState == .completed)

        // Restart from completed state (PRD Section 9.3: "restarts form from first move")
        mockManager.reset()
        try viewModel.startSession()

        // Manager should be started again
        #expect(mockManager.startCalled, "startSession should call manager.start() when restarting")

        // After restart, simulate manager resetting to first move
        mockManager.simulateMoveChange(index: 0, text: "Move 1")
        mockManager.simulateStateChange(.speaking)

        // Verify we're back at the first move
        #expect(viewModel.currentMoveIndex == 0, "Restart should reset to first move")
        #expect(viewModel.currentMoveText == "Move 1", "Restart should show first move text")
    }
}
