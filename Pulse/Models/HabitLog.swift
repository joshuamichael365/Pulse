//
//  HabitLog.swift
//  Pulse
//
//  Created by Joshua Michael on 6/13/26.
//

import Foundation
import SwiftData

/// The time of day a habit log entry was recorded.
enum TimeOfDay: String, Codable {
    case morning, afternoon, evening, night
}

/// A single recorded completion of a habit on a specific day.
///
/// HabitLog captures one instance of a habit being completed or skipped.
/// Each log entry is linked to its parent Habit and feeds into the RAG
/// corpus to enable pattern detection across time.
@Model
final class HabitLog {

    /// The unique identifier for this log entry.
    var id: UUID

    /// The date this log entry is for.
    var date: Date

    /// The exact timestamp when the user marked the habit complete.
    var completedAt: Date?

    /// Whether the habit was completed on this day.
    var isCompleted: Bool

    /// The recorded value for quantitative habits e.g. 7 glasses of water.
    var value: Double?

    /// The time of day this habit was completed.
    var timeOfDay: TimeOfDay?

    /// An optional in-the-moment note about this specific completion.
    var notes: String?

    /// The habit this log entry belongs to.
    var habit: Habit

    /// The date and time this log entry was created.
    var createdAt: Date

    /// Creates a new habit log entry for a specific habit and date.
    ///
    /// - Parameters:
    ///   - habit: The habit this log entry belongs to.
    ///   - date: The date this log is recording. Defaults to today.
    ///   - isCompleted: Whether the habit was completed. Defaults to false.
    ///   - timeOfDay: The time of day the habit was completed.
    ///   - value: The recorded value for quantitative habits.
    ///   - notes: An optional note about this specific completion.
    init(
        habit: Habit,
        date: Date = Date(),
        isCompleted: Bool = false,
        timeOfDay: TimeOfDay? = nil,
        value: Double? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.habit = habit
        self.date = date
        self.isCompleted = isCompleted
        self.timeOfDay = timeOfDay
        self.value = value
        self.notes = notes
        self.createdAt = Date()
    }
}
