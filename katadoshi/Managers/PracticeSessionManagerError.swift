//
//  PracticeSessionManagerError.swift
//  katadoshi
//
//  Created by Claude Code on 11/3/25.
//

import Foundation

/// Errors that can occur during practice session management
enum PracticeSessionManagerError: Error, Equatable, CustomStringConvertible {
    case emptyForm
    case invalidMoveIndex
    case serviceUnavailable
    case permissionDenied

    var description: String {
        switch self {
        case .emptyForm:
            return "form has no moves"
        case .invalidMoveIndex:
            return "invalid move index"
        case .serviceUnavailable:
            return "service is unavailable"
        case .permissionDenied:
            return "permission denied"
        }
    }
}
