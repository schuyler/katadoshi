//
//  VoiceCommand.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import Foundation

/// Voice commands recognized by speech recognition service
/// PRD Section 5.3 specifies 8 command variants, plus "restart" for going back to move 1
public enum VoiceCommand: Equatable, Hashable {
    case start
    case begin
    case restart  // Go back to move 1 from any state
    case next
    case go
    case back
    case `repeat`  // Backticks because 'repeat' is Swift keyword
    case stop
    case pause
}

/// Pure function to parse voice commands from transcript text
/// Used by SpeechRecognitionService for command recognition
/// - Parameter transcript: Raw text from speech recognition
/// - Returns: VoiceCommand if recognized, nil otherwise
public func parseCommand(from transcript: String) -> VoiceCommand? {
    let lowercased = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    // Match commands in priority order
    // Order matters - first match wins
    // Note: Check "restart" before "start" since "restart" contains "start"
    // Note: Check "back" before "go" to handle "go back" phrase correctly
    if lowercased.contains("restart") {
        return .restart
    } else if lowercased.contains("start") {
        return .start
    } else if lowercased.contains("begin") {
        return .begin
    } else if lowercased.contains("next") {
        return .next
    } else if lowercased.contains("back") {
        return .back
    } else if lowercased.contains("go") {
        return .go
    } else if lowercased.contains("repeat") {
        return .repeat
    } else if lowercased.contains("stop") {
        return .stop
    } else if lowercased.contains("pause") {
        return .pause
    }

    return nil  // Unrecognized - continue listening
}
