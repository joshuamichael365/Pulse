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

/// A habit's record for one day. There is at most one log per habit per day.
///
/// Completion is never stored. For a yes/no habit, the log existing means it was done.
/// For a quantity habit, it's done when `value` reaches `targetAtLog`. Each log feeds into
/// the RAG corpus to enable pattern detection across time.
@Model
final class HabitLog {

    /// The unique identifier for this log entry.
    var id: UUID

    /// The day this log is for, stored as the start of that day.
    var date: Date

    /// When the habit was completed that day. Nil until the log is complete.
    var completedAt: Date?

    /// The amount logged for quantity habits, including partial amounts. Nil for yes/no habits.
    var value: Double?

    /// The habit's target on this day, so later target changes don't rewrite history.
    var targetAtLog: Double?

    /// The time of day this habit was last logged.
    var timeOfDay: TimeOfDay?

    /// An optional in-the-moment note about this day's entry.
    var notes: String?

    /// The habit this log entry belongs to.
    var habit: Habit?

    /// The date and time this log entry was created.
    var createdAt: Date

    /// Whether this log counts as the habit being done for its day.
    var isComplete: Bool {
        guard let habit else { return false }
        switch habit.type {
        case .yesNo:
            return true
        case .quantity:
            return HabitProgress.completionFraction(value: value, target: targetAtLog) >= 1
        }
    }

    /// Creates a new log entry for a specific day. Attach it to a habit after inserting it.
    ///
    /// - Parameters:
    ///   - date: Any time on the day this log is recording. Stored as the start of that day.
    ///   - value: The amount logged for quantity habits.
    ///   - targetAtLog: The habit's target on this day.
    ///   - timeOfDay: The time of day the habit was logged.
    ///   - notes: An optional note about this day's entry.
    ///   - calendar: The calendar used to find the start of the day.
    init(
        date: Date = Date(),
        value: Double? = nil,
        targetAtLog: Double? = nil,
        timeOfDay: TimeOfDay? = nil,
        notes: String? = nil,
        calendar: Calendar = .current
    ) {
        self.id = UUID()
        self.date = calendar.startOfDay(for: date)
        self.value = value
        self.targetAtLog = targetAtLog
        self.timeOfDay = timeOfDay
        self.notes = notes
        self.createdAt = Date()
    }
}
