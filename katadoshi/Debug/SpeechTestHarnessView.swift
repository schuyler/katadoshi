//
//  SpeechTestHarnessView.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//
//  Debug-only view for manual testing of SpeechRecognitionService authorization flows
//

#if DEBUG
import SwiftUI
import Speech

/// Test harness for manually verifying speech recognition authorization behavior
/// Access via debug menu in app for development testing
struct SpeechTestHarnessView: View {
    @StateObject private var testRunner = SpeechTestRunner()

    var body: some View {
        List {
            Section {
                Text("Manual testing tool for speech recognition authorization. Tests behavior that cannot be unit tested.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Current Authorization Status") {
                HStack {
                    Text("Microphone Permission:")
                    Spacer()
                    Text(testRunner.authStatus)
                        .bold()
                        .foregroundColor(statusColor(testRunner.authStatus))
                }

                Button("Request Permission") {
                    testRunner.requestPermission()
                }
                .disabled(testRunner.authStatus == "authorized")

                Button("Refresh Status") {
                    testRunner.updateAuthStatus()
                }
            }

            Section("Service Tests") {
                Button("Test: Start Listening") {
                    testRunner.testStartListening()
                }

                Button("Test: Stop Listening") {
                    testRunner.testStopListening()
                }

                Button("Test: Permission Denied Flow") {
                    testRunner.testPermissionDeniedFlow()
                }

                Button("Clear Results") {
                    testRunner.clearResults()
                }
            }

            Section("Test Results") {
                if testRunner.results.isEmpty {
                    Text("No tests run yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(testRunner.results, id: \.id) { result in
                        HStack(alignment: .top) {
                            Text(result.icon)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.message)
                                    .font(.body)
                                if let detail = result.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .foregroundColor(result.passed == true ? .green : result.passed == false ? .red : .primary)
                    }
                }
            }

            Section("Quick Reference") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expected Behaviors:")
                        .font(.headline)

                    referenceItem(
                        status: "authorized",
                        behavior: "Service starts, isListening = true"
                    )
                    referenceItem(
                        status: "denied/restricted",
                        behavior: "onPermissionDenied fires, isListening = false"
                    )
                    referenceItem(
                        status: "notDetermined",
                        behavior: "System alert appears on first request"
                    )
                }
                .font(.caption)
            }

            Section("Integration Test Document") {
                Link("View Full Test Specification →",
                     destination: URL(string: "file:///Users/sderle/code/katadoshi/docs/Integration-Test-SpeechRecognition.md")!)
                    .font(.caption)
            }
        }
        .navigationTitle("Speech Test Harness")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "authorized":
            return .green
        case "denied", "restricted":
            return .red
        case "notDetermined":
            return .orange
        default:
            return .secondary
        }
    }

    private func referenceItem(status: String, behavior: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            VStack(alignment: .leading) {
                Text(status)
                    .bold()
                Text(behavior)
            }
        }
    }
}

/// Test runner that executes speech recognition tests and tracks results
@MainActor
class SpeechTestRunner: ObservableObject {
    @Published var authStatus: String = ""
    @Published var results: [TestResult] = []

    private var service: SpeechRecognitionService?

    init() {
        updateAuthStatus()
    }

    func updateAuthStatus() {
        let status = SFSpeechRecognizer.authorizationStatus()
        authStatus = "\(status)".replacingOccurrences(of: "SFSpeechRecognizerAuthorizationStatus.", with: "")
    }

    func requestPermission() {
        addResult(.info("Requesting speech recognition permission..."))

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.updateAuthStatus()
                self?.addResult(.info("Permission status updated: \(status)"))

                switch status {
                case .authorized:
                    self?.addResult(.pass("Permission granted successfully"))
                case .denied:
                    self?.addResult(.fail("Permission denied by user"))
                case .restricted:
                    self?.addResult(.fail("Permission restricted (Screen Time or MDM)"))
                case .notDetermined:
                    self?.addResult(.info("Permission not yet determined"))
                @unknown default:
                    self?.addResult(.fail("Unknown permission status"))
                }
            }
        }
    }

    func testStartListening() {
        clearResults()
        addResult(.info("Testing startListening() with current permissions"))

        // Create fresh service instance
        service = SpeechRecognitionService()

        var permissionDeniedFired = false
        var recognitionUnavailableFired = false

        service?.onPermissionDenied = { [weak self] in
            permissionDeniedFired = true
            self?.addResult(.fail("onPermissionDenied callback fired",
                                 detail: "Service detected denied/restricted permission"))
        }

        service?.onRecognitionUnavailable = { [weak self] in
            recognitionUnavailableFired = true
            self?.addResult(.fail("onRecognitionUnavailable callback fired",
                                 detail: "Recognizer not available or audio engine error"))
        }

        service?.didRecognizeCommand = { [weak self] command in
            self?.addResult(.pass("Command recognized: \(command)"))
        }

        // Start listening
        service?.startListening()

        // Check results after brief delay to allow callbacks
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let service = self.service else { return }

            if service.isListening {
                self.addResult(.pass("Service is listening",
                                    detail: "isListening = true"))
                self.addResult(.info("Speak a command to test recognition"))
            } else {
                self.addResult(.fail("Service is NOT listening",
                                    detail: "isListening = false"))

                if !permissionDeniedFired && !recognitionUnavailableFired {
                    self.addResult(.fail("No error callbacks fired",
                                        detail: "Expected onPermissionDenied or onRecognitionUnavailable"))
                }
            }

            self.updateAuthStatus()
        }
    }

    func testStopListening() {
        guard let service = service else {
            addResult(.fail("No active service",
                           detail: "Run 'Test: Start Listening' first"))
            return
        }

        addResult(.info("Testing stopListening()"))

        let wasListening = service.isListening
        service.stopListening()

        if wasListening && !service.isListening {
            addResult(.pass("Service stopped successfully",
                           detail: "isListening changed from true to false"))
        } else if !wasListening {
            addResult(.info("Service was not listening",
                           detail: "stopListening() called on idle service (should be safe)"))
        } else {
            addResult(.fail("Service still listening after stop",
                           detail: "isListening should be false"))
        }
    }

    func testPermissionDeniedFlow() {
        clearResults()

        updateAuthStatus()

        if authStatus == "authorized" {
            addResult(.fail("Cannot test denied flow - permission currently authorized",
                           detail: "Go to Settings → Privacy → Microphone → Kata Dōshi → Toggle OFF"))
            return
        }

        addResult(.info("Testing permission denied/restricted flow"))
        addResult(.info("Current permission: \(authStatus)"))

        service = SpeechRecognitionService()

        var callbackFired = false
        service?.onPermissionDenied = { [weak self] in
            callbackFired = true
            self?.addResult(.pass("onPermissionDenied callback fired correctly",
                                 detail: "Service detected unauthorized state"))
        }

        service?.startListening()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let service = self.service else { return }

            if callbackFired {
                self.addResult(.pass("Callback timing correct",
                                    detail: "Fired immediately on startListening()"))
            } else {
                self.addResult(.fail("onPermissionDenied NOT fired",
                                    detail: "Expected callback for \(self.authStatus) status"))
            }

            if !service.isListening {
                self.addResult(.pass("Service correctly blocked startup",
                                    detail: "isListening = false"))
            } else {
                self.addResult(.fail("Service incorrectly started",
                                    detail: "Should not start without permission"))
            }
        }
    }

    func clearResults() {
        results.removeAll()
    }

    private func addResult(_ result: TestResult) {
        results.append(result)
    }
}

/// Result of a test case execution
struct TestResult: Identifiable {
    let id = UUID()
    let passed: Bool?
    let message: String
    let detail: String?
    let icon: String

    static func pass(_ message: String, detail: String? = nil) -> TestResult {
        TestResult(passed: true, message: message, detail: detail, icon: "✓")
    }

    static func fail(_ message: String, detail: String? = nil) -> TestResult {
        TestResult(passed: false, message: message, detail: detail, icon: "✗")
    }

    static func info(_ message: String, detail: String? = nil) -> TestResult {
        TestResult(passed: nil, message: message, detail: detail, icon: "ℹ️")
    }
}

#Preview {
    NavigationStack {
        SpeechTestHarnessView()
    }
}

#endif
