//
//  Form.swift
//  katadoshi
//
//  Created by Claude Code on 11/2/25.
//

import Foundation

/// Represents a martial arts form (kata) with its sequence of moves.
///
/// A Form contains a unique identifier, title, list of moves, and timestamps
/// for creation and last practice. Forms are used throughout the app for
/// practice session management and persistence.
struct Form: Identifiable, Codable, Equatable {
    /// Unique identifier for the form
    let id: UUID

    /// Display name of the form (e.g., "Heian Shodan")
    var title: String

    /// Ordered list of move instructions
    var moves: [String]

    /// Timestamp when the form was created
    let dateCreated: Date

    /// Timestamp when the form was last practiced
    var lastPracticed: Date

    /// Creates a new Form with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - title: Display name of the form
    ///   - moves: Array of move instructions
    ///   - dateCreated: Creation timestamp (defaults to current date)
    ///   - lastPracticed: Last practice timestamp (defaults to current date)
    init(id: UUID = UUID(),
         title: String,
         moves: [String],
         dateCreated: Date = Date(),
         lastPracticed: Date = Date()) {
        self.id = id
        self.title = title
        self.moves = moves
        self.dateCreated = dateCreated
        self.lastPracticed = lastPracticed
    }
}
