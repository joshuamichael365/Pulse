//
//  HabitViewModel.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData
import Observation

/// Manages all habit-related data and business logic for the Habits feature.
///
/// HabitViewModel acts as the bridge between SwiftData and the Habits UI.
/// It handles creating, updating, archiving, and logging habits, and exposes
/// prepared data for views to display.
@Observable
final class HabitViewModel {

    // MARK: - Properties

    /// All active habits fetched from SwiftData.
    var habits: [Habit] = []

    /// Whether data is currently being loaded.
    var isLoading: Bool = false

    /// An error message to display if something goes wrong.
    var errorMessage: String? = nil

    /// The SwiftData model context used for all database operations.
    private var modelContext: ModelContext

    // MARK: - Init

    /// Creates a new HabitViewModel with the given SwiftData context.
    /// - Parameter context: The SwiftData ModelContext for database operations.
    init(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Habit Operations

    /// Fetches all active (non-archived) habits from SwiftData.
    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            habits = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch habits: \(error.localizedDescription)"
        }
    }

    /// Creates a new habit and saves it to SwiftData.
    /// - Parameters:
    ///   - name: The name of the habit.
    ///   - category: The category the habit belongs to.
    ///   - type: Whether this is a habit to build or break.
    ///   - frequency: How often the habit should be completed.
    ///   - emoji: The emoji identifier for the habit.
    ///   - color: The display color for the habit.
    func createHabit(
        name: String,
        category: HabitCategory,
        type: HabitType = .goodHabit,
        frequency: HabitFrequency = .daily,
        emoji: String = "⭐️",
        color: String = "blue"
    ) {
        let habit = Habit(
            name: name,
            emoji: emoji,
            color: color,
            category: category,
            type: type,
            frequency: frequency
        )
        modelContext.insert(habit)
        save()
        fetchHabits()
    }

    /// Marks a habit as completed for today by creating a HabitLog entry.
    /// - Parameter habit: The habit to mark as complete.
    func markHabitComplete(_ habit: Habit) {
        let log = HabitLog(
            habit: habit,
            date: Date(),
            isCompleted: true,
            timeOfDay: currentTimeOfDay()
        )
        modelContext.insert(log)
        habit.streak += 1
        habit.totalCompletions += 1
        habit.longestStreak = max(habit.streak, habit.longestStreak)
        habit.updatedAt = Date()
        save()
    }

    /// Archives a habit so it no longer appears in the active list.
    /// - Parameter habit: The habit to archive.
    func archiveHabit(_ habit: Habit) {
        habit.archivedAt = Date()
        habit.updatedAt = Date()
        save()
        fetchHabits()
    }

    /// Deletes a habit permanently from SwiftData.
    /// - Parameter habit: The habit to delete.
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        save()
        fetchHabits()
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

    /// Returns the current time of day based on the system clock.
    private func currentTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }
}
