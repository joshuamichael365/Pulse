//
//  Reflection.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData

/// The sentiment of a reflection entry detected by the AI.
enum ReflectionSentiment: String, Codable {
    case positive, neutral, negative, mixed
}

/// A free-text reflection entry written by the user.
///
/// Reflections are standalone journal entries not tied to a specific check-in.
/// They form a significant part of the RAG corpus — capturing the user's
/// thoughts, feelings, and experiences in their own words. The richer the
/// reflection, the more context the AI coach has to work with.
@Model
final class Reflection {

    /// The unique identifier for this reflection.
    var id: UUID

    /// The date this reflection was written.
    var date: Date

    /// The main body text of the reflection.
    var content: String

    /// An optional title the user gives this reflection.
    var title: String?

    /// The AI-detected sentiment of this reflection.
    var sentiment: ReflectionSentiment?

    /// Tags the user applies to this reflection for grouping.
    var tags: [String]

    /// Whether this reflection has been embedded and added to the RAG corpus.
    var isEmbedded: Bool

    /// The date and time this reflection was created.
    var createdAt: Date

    /// The date and time this reflection was last modified.
    var updatedAt: Date

    /// Creates a new reflection entry.
    ///
    /// - Parameters:
    ///   - content: The main body text of the reflection.
    ///   - title: An optional title for this reflection.
    ///   - date: The date of this reflection. Defaults to now.
    ///   - tags: Optional tags for grouping. Defaults to empty.
    init(
        content: String,
        title: String? = nil,
        date: Date = Date(),
        tags: [String] = []
    ) {
        self.id = UUID()
        self.content = content
        self.title = title
        self.date = date
        self.tags = tags
        self.sentiment = nil
        self.isEmbedded = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
