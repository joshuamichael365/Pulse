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
    case health, fitness, sleep, mindfulness, nutrition, productivity, social, other
}

/// How a habit is tracked: a single yes/no check, or an amount toward a target.
enum HabitType: String, Codable {
    case yesNo, quantity
}

/// The fixed list of units a quantity habit can use.
///
/// Step size is derived from the unit here and is never set by the user.
enum HabitUnit: String, Codable, CaseIterable {
    case glasses, minutes, steps, pages, times

    /// The amount one tap adds when logging. Nil means the unit uses typed entry instead.
    var stepSize: Double? {
        switch self {
        case .glasses, .times: return 1
        case .minutes, .pages: return 5
        case .steps:           return nil
        }
    }
}

/// One stretch of time during which a habit followed a particular weekly schedule.
///
/// Habits keep a history of these so that editing a schedule never changes how past
/// days are judged. A missed day has no log, so the schedule for that day has to be
/// recoverable from the habit itself.
struct SchedulePeriod: Codable, Equatable {

    /// The first day (start of day) this schedule applies to.
    var effectiveFrom: Date

    /// Scheduled days as `Calendar` weekdays, 1 (Sunday) through 7 (Saturday).
    var weekdays: [Int]
}

/// A habit the user wants to track in Pulse.
///
/// Habits are the core data model in the Pulse app. Streaks, totals, and completion are
/// never stored; they are calculated from the habit's logs and schedule history by
/// `HabitProgress`. Habit data is ingested into the RAG corpus to enable personalised
/// AI coaching insights over time.
@Model
final class Habit {

    /// Every weekday, used as the "Daily" schedule.
    static let allWeekdays = Array(1...7)

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

    /// Whether this habit is a yes/no check or an amount toward a target.
    var type: HabitType

    /// The target amount for quantity habits e.g. 8 glasses of water. Nil for yes/no habits.
    var targetValue: Double?

    /// The unit for quantity habits. Nil for yes/no habits.
    var unit: HabitUnit?

    /// The preset this habit was created from, or nil for a custom habit.
    var presetID: String?

    /// Every schedule this habit has followed, oldest first. Never empty: the first
    /// period is created in `init`, and changes go through `setSchedule(_:from:calendar:)`.
    /// Every period has at least one weekday.
    private(set) var scheduleHistory: [SchedulePeriod]

    /// Every log recorded for this habit. Deleting the habit deletes its logs.
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

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

    // MARK: - Computed

    /// The weekdays this habit is scheduled on now, from the latest schedule period.
    var scheduledWeekdays: [Int] {
        scheduleHistory.last?.weekdays ?? []
    }

    /// The first day this habit was tracked, from the first schedule period.
    var startDate: Date {
        scheduleHistory.first?.effectiveFrom ?? createdAt
    }

    /// The amount one tap adds when logging, or nil for typed entry and yes/no habits.
    var stepSize: Double? {
        unit?.stepSize
    }

    /// Creates a new habit with its first schedule period.
    ///
    /// - Parameters:
    ///   - name: The display name of the habit.
    ///   - emoji: The emoji used as a visual identifier. Defaults to ⭐️.
    ///   - color: The display color as a hex string. Defaults to blue.
    ///   - category: The category this habit belongs to. Defaults to other.
    ///   - type: Whether this is a yes/no or quantity habit. Defaults to yes/no.
    ///   - unit: The unit for quantity habits.
    ///   - targetValue: The target amount for quantity habits.
    ///   - weekdays: Scheduled `Calendar` weekdays. Defaults to every day. Must contain at
    ///     least one valid weekday; callers validate this first (see `HabitViewModel`).
    ///   - presetID: The preset this habit came from, if any.
    ///   - startDate: The first day the habit is tracked. Defaults to now.
    ///   - calendar: The calendar used to find the start of the day.
    init(
        name: String,
        emoji: String = "⭐️",
        color: String = "blue",
        category: HabitCategory = .other,
        type: HabitType = .yesNo,
        unit: HabitUnit? = nil,
        targetValue: Double? = nil,
        weekdays: [Int] = Habit.allWeekdays,
        presetID: String? = nil,
        startDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.color = color
        self.category = category
        self.type = type
        self.unit = unit
        self.targetValue = targetValue
        self.presetID = presetID

        let days = Habit.normalized(weekdays)
        // An empty schedule is a programming error: the view model rejects it before we get
        // here. Crash in debug builds so it's caught; in release, fall back to every day
        // because a new habit needs some schedule and there's no previous one to keep.
        assert(!days.isEmpty, "Habit \"\(name)\" created with no valid weekdays: \(weekdays)")
        self.scheduleHistory = [
            SchedulePeriod(
                effectiveFrom: calendar.startOfDay(for: startDate),
                weekdays: days.isEmpty ? Habit.allWeekdays : days
            )
        ]
        self.reminderEnabled = false
        self.vacationMode = false
        self.sortOrder = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Schedule

    /// Changes the schedule from the given day onward, leaving past days untouched.
    ///
    /// A second change on the same day replaces that day's period instead of adding another.
    /// - Parameters:
    ///   - weekdays: The new scheduled `Calendar` weekdays. Must contain at least one valid
    ///     weekday; callers validate this first (see `HabitViewModel`).
    ///   - date: The day the new schedule takes effect. Defaults to now.
    ///   - calendar: The calendar used to find the start of the day.
    func setSchedule(_ weekdays: [Int], from date: Date = Date(), calendar: Calendar = .current) {
        let normalizedDays = Habit.normalized(weekdays)
        // Same rule as init: crash in debug builds; in release, keep the current schedule.
        guard !normalizedDays.isEmpty else {
            assertionFailure("setSchedule called with no valid weekdays: \(weekdays)")
            return
        }
        guard normalizedDays != scheduledWeekdays else { return }

        // History only moves forward, so a change can never rewrite an earlier period.
        let lastStart = scheduleHistory.last?.effectiveFrom ?? .distantPast
        let start = max(calendar.startOfDay(for: date), lastStart)
        let period = SchedulePeriod(effectiveFrom: start, weekdays: normalizedDays)

        if start == lastStart {
            scheduleHistory[scheduleHistory.count - 1] = period
        } else {
            scheduleHistory.append(period)
        }
        updatedAt = Date()
    }

    /// Sorts and de-duplicates weekdays, dropping anything outside 1...7.
    /// Returns an empty array if no valid weekdays remain; it never substitutes a schedule.
    static func normalized(_ weekdays: [Int]) -> [Int] {
        Set(weekdays.filter { allWeekdays.contains($0) }).sorted()
    }
}
