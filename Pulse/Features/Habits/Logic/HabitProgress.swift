//
//  HabitProgress.swift
//  Pulse
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation

/// Pure calculations for habit completion, schedules, and streaks.
///
/// Nothing here touches SwiftData. Every function takes plain values plus a `Calendar`
/// and `today`, so results are deterministic and easy to unit test.
enum HabitProgress {

    // MARK: - Completion

    /// How far a quantity log is toward its target, from 0 to 1.
    ///
    /// Amounts over the target are capped at 1. A missing or non-positive target returns 0,
    /// since there's nothing meaningful to measure against.
    static func completionFraction(value: Double?, target: Double?) -> Double {
        guard let target, target > 0 else { return 0 }
        let fraction = (value ?? 0) / target
        return min(max(fraction, 0), 1)
    }

    // MARK: - Schedule

    /// The schedule period in effect on a given day, or nil if the day is before the habit started.
    static func period(
        on day: Date,
        in history: [SchedulePeriod],
        calendar: Calendar
    ) -> SchedulePeriod? {
        let dayStart = calendar.startOfDay(for: day)
        return history
            .filter { $0.effectiveFrom <= dayStart }
            .max { $0.effectiveFrom < $1.effectiveFrom }
    }

    /// Whether the habit was scheduled on a given day, using the schedule in effect that day.
    ///
    /// Days before the first period are never scheduled, which handles the habit's start date.
    static func isScheduled(
        on day: Date,
        history: [SchedulePeriod],
        calendar: Calendar
    ) -> Bool {
        guard let period = period(on: day, in: history, calendar: calendar) else { return false }
        return period.weekdays.contains(calendar.component(.weekday, from: day))
    }

    // MARK: - Streaks

    /// The number of consecutive scheduled days completed, counting back from today.
    ///
    /// - Unscheduled days are skipped: they neither add to nor break the streak.
    /// - If today is scheduled but not done yet, the streak runs through yesterday.
    /// - A missed scheduled day before today ends the streak.
    ///
    /// - Parameters:
    ///   - completedDays: The start-of-day dates with a complete log.
    ///   - history: The habit's schedule history.
    ///   - today: The current date.
    ///   - calendar: The calendar used for days and weekdays.
    static func currentStreak(
        completedDays: Set<Date>,
        history: [SchedulePeriod],
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard let firstDay = firstDay(of: history) else { return 0 }

        let todayStart = calendar.startOfDay(for: today)
        var day = todayStart
        var streak = 0

        while day >= firstDay {
            if isScheduled(on: day, history: history, calendar: calendar) {
                if completedDays.contains(day) {
                    streak += 1
                } else if day != todayStart {
                    break
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// The longest run of consecutive scheduled days completed, from the start through today.
    ///
    /// Uses the same rules as `currentStreak`: unscheduled days are skipped, and today not
    /// being done yet doesn't end a run.
    static func longestStreak(
        completedDays: Set<Date>,
        history: [SchedulePeriod],
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard let firstDay = firstDay(of: history) else { return 0 }

        let todayStart = calendar.startOfDay(for: today)
        var day = firstDay
        var run = 0
        var best = 0

        while day <= todayStart {
            if isScheduled(on: day, history: history, calendar: calendar) {
                if completedDays.contains(day) {
                    run += 1
                    best = max(best, run)
                } else if day != todayStart {
                    run = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }

    // MARK: - Helpers

    /// The earliest day covered by the schedule history.
    private static func firstDay(of history: [SchedulePeriod]) -> Date? {
        history.map(\.effectiveFrom).min()
    }
}
