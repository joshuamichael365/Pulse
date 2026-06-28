//
//  ReflectionViewModel.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData
import Observation

/// Manages all reflection related data and business logic.
///
/// ReflectionViewModel handles creating, fetching, and searching
/// reflection entries. Reflections form a core part of the RAG corpus
/// providing rich free-text context for the AI coach to reason over.
@Observable
final class ReflectionViewModel {

    // MARK: - Properties

    /// All reflections fetched from SwiftData sorted by date descending.
    var reflections: [Reflection] = []

    /// Whether data is currently being loaded.
    var isLoading: Bool = false

    /// An error message to display if something goes wrong.
    var errorMessage: String? = nil

    /// The current search text for filtering reflections.
    var searchText: String = ""

    /// Reflections filtered by the current search text.
    var filteredReflections: [Reflection] {
        if searchText.isEmpty {
            return reflections
        }
        return reflections.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// The SwiftData model context used for all database operations.
    private var modelContext: ModelContext

    // MARK: - Init

    /// Creates a new ReflectionViewModel with the given SwiftData context.
    /// - Parameter context: The SwiftData ModelContext for database operations.
    init(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Reflection Operations

    /// Fetches all reflections from SwiftData sorted by date descending.
    func fetchReflections() {
        let descriptor = FetchDescriptor<Reflection>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            reflections = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch reflections: \(error.localizedDescription)"
        }
    }

    /// Creates and saves a new reflection entry.
    /// - Parameters:
    ///   - content: The main body text of the reflection.
    ///   - title: An optional title for this reflection.
    ///   - tags: Optional tags for grouping.
    func createReflection(
        content: String,
        title: String? = nil,
        tags: [String] = []
    ) {
        let reflection = Reflection(
            content: content,
            title: title,
            tags: tags
        )
        modelContext.insert(reflection)
        save()
        fetchReflections()
    }

    /// Deletes a reflection permanently from SwiftData.
    /// - Parameter reflection: The reflection to delete.
    func deleteReflection(_ reflection: Reflection) {
        modelContext.delete(reflection)
        save()
        fetchReflections()
    }

    /// Updates an existing reflection's content.
    /// - Parameters:
    ///   - reflection: The reflection to update.
    ///   - content: The new content.
    ///   - title: The new title.
    func updateReflection(
        _ reflection: Reflection,
        content: String,
        title: String? = nil
    ) {
        reflection.content = content
        reflection.title = title
        reflection.updatedAt = Date()
        save()
    }

    // MARK: - Helpers

    /// Saves the current SwiftData context.
    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
