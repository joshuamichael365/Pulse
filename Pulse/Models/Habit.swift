//
//  Habit.swift
//  Pulse
//
//  Created by Joshua Michael on 6/13/26.
//

import Foundation
import SwiftData

/// The category a habit belongs to, used for grouping and RAG correlation.
enum HabitCategory: String, Codable {
    case health, fitness, sleep, mindfulness, nutrition, productivity, social
}

/// Whether the habit is one the user wants to build or break.
enum HabitType: String, Codable {
    case goodHabit, badHabit
}

/// How often the habit should be completed.
enum HabitFrequency: String, Codable {
    case daily, weekdays, weekends, custom
}

/// A habit the user wants to track in Pulse.
///
/// Habits are the core data model in the Pulse app. Each habit belongs to a category
/// and tracks the user's streak and completion history. Habit data is ingested into
/// the RAG corpus to enable personalised AI coaching insights over time.
@Model
final class Habit {

    /// The unique identifier for this habit.
    var id: UUID

    /// The display name of the habit e.g. "Exercise" or "Meditate".
    var name: String

    /// An optional longer description of the habit.
    var habitDescription: String?

    /// The emoji used as a visual identifier in the UI.
    var emoji: String

    /// The display color for this habit stored as a hex string.
    var color: String

    /// The category this habit belongs to e.g. health, fitness, sleep.
    var category: HabitCategory

    /// Whether this is a habit the user wants to build or break.
    var type: HabitType

    /// How frequently this habit should be completed.
    var frequency: HabitFrequency

    /// The target value for quantitative habits e.g. 8 glasses of water.
    var targetValue: Double?

    /// The unit for quantitative habits e.g. "glasses", "km", "minutes".
    var unit: String?

    /// The current number of consecutive days the habit has been completed.
    var streak: Int

    /// The all time longest streak achieved for this habit.
    var longestStreak: Int

    /// The total number of times this habit has been completed across all time.
    var totalCompletions: Int

    /// The date the user started tracking this habit.
    var startDate: Date

    /// The date this habit was archived. Nil if the habit is still active.
    var archivedAt: Date?

    /// Whether the user has enabled reminders for this habit.
    var reminderEnabled: Bool

    /// Whether the habit is paused via vacation mode, preserving the streak.
    var vacationMode: Bool

    /// Optional notes the user has written about this habit, used as RAG context.
    var notes: String?

    /// The user's goal for this habit e.g. "I want more energy". Used as RAG context.
    var goal: String?

    /// The user defined display order for this habit in the list.
    var sortOrder: Int

    /// The date and time this habit was created.
    var createdAt: Date

    /// The date and time this habit was last modified.
    var updatedAt: Date

    /// Creates a new habit with the given properties.
    ///
    /// - Parameters:
    ///   - name: The display name of the habit.
    ///   - emoji: The emoji used as a visual identifier. Defaults to ⭐️.
    ///   - color: The display color as a hex string. Defaults to blue.
    ///   - category: The category this habit belongs to.
    ///   - type: Whether this is a habit to build or break. Defaults to goodHabit.
    ///   - frequency: How often the habit should be completed. Defaults to daily.
    init(
        name: String,
        emoji: String = "⭐️",
        color: String = "blue",
        category: HabitCategory,
        type: HabitType = .goodHabit,
        frequency: HabitFrequency = .daily
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.color = color
        self.category = category
        self.type = type
        self.frequency = frequency
        self.streak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.startDate = Date()
        self.reminderEnabled = false
        self.vacationMode = false
        self.sortOrder = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
