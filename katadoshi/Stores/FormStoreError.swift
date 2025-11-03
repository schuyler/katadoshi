//
//  FormStoreError.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import Foundation

/// Errors that can occur during form store operations
enum FormStoreError: Error, Equatable, CustomStringConvertible {
    case emptyTitle
    case emptyMoves
    case moveTooLong(length: Int)
    case formNotFound
    case duplicateID

    var description: String {
        switch self {
        case .emptyTitle:
            return "Form title cannot be empty"
        case .emptyMoves:
            return "Form must have at least one move"
        case .moveTooLong(let length):
            return "Move is too long (\(length) characters). Maximum is 200 characters."
        case .formNotFound:
            return "Form not found"
        case .duplicateID:
            return "A form with this ID already exists"
        }
    }
}
