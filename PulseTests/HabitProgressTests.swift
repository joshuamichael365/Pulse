//
//  HabitProgressTests.swift
//  PulseTests
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation
import Testing
@testable import Pulse

@MainActor
struct HabitProgressTests {

    private let calendar = HabitTestSupport.calendar
    private typealias T = HabitTestSupport

    // MARK: - Completion fraction

    @Test func partialAmountIsAFraction() {
        #expect(HabitProgress.completionFraction(value: 4, target: 8) == 0.5)
    }

    @Test func overTargetIsCappedAtOne() {
        #expect(HabitProgress.completionFraction(value: 10, target: 8) == 1)
    }

    @Test func missingValueIsZero() {
        #expect(HabitProgress.completionFraction(value: nil, target: 8) == 0)
    }

    @Test func zeroOrMissingTargetIsZero() {
        #expect(HabitProgress.completionFraction(value: 5, target: 0) == 0)
        #expect(HabitProgress.completionFraction(value: 5, target: nil) == 0)
    }

    // MARK: - Schedule

    @Test func dayBeforeFirstPeriodIsNotScheduled() {
        let history = T.history(from: 21)
        #expect(!HabitProgress.isScheduled(on: T.sep(20), history: history, calendar: calendar))
        #expect(HabitProgress.isScheduled(on: T.sep(21), history: history, calendar: calendar))
    }

    @Test func weekdayScheduleSkipsOtherDays() {
        let history = T.history(from: 14, weekdays: T.monWedFri)
        #expect(HabitProgress.isScheduled(on: T.sep(21), history: history, calendar: calendar))  // Mon
        #expect(!HabitProgress.isScheduled(on: T.sep(22), history: history, calendar: calendar)) // Tue
    }

    // MARK: - Current streak

    @Test func dailyStreakCountsConsecutiveDays() {
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(21, 22, 23, 24, 25, 26),
            history: T.history(from: 14),
            today: T.sep(26),
            calendar: calendar
        )
        #expect(streak == 6)
    }

    @Test func restDaysDontBreakAWeekdayStreak() {
        // Mon/Wed/Fri habit, done every scheduled day this week. Tue, Thu, Sat are rest days.
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(21, 23, 25),
            history: T.history(from: 14, weekdays: T.monWedFri),
            today: T.sep(26),
            calendar: calendar
        )
        #expect(streak == 3)
    }

    @Test func todayNotDoneYetKeepsTheStreak() {
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(22, 23, 24, 25),
            history: T.history(from: 14),
            today: T.sep(26),
            calendar: calendar
        )
        #expect(streak == 4)
    }

    @Test func missedScheduledDayResetsTheStreak() {
        // Sep 23 was missed.
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(21, 22, 24, 25),
            history: T.history(from: 14),
            today: T.sep(25),
            calendar: calendar
        )
        #expect(streak == 2)
    }

    @Test func daysBeforeTheStartDontCount() {
        // Logs before the habit started (Sep 21) are ignored.
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(18, 19, 20, 21, 22),
            history: T.history(from: 21),
            today: T.sep(22),
            calendar: calendar
        )
        #expect(streak == 2)
    }

    @Test func scheduleChangeKeepsTheOldStreak() {
        // Mon/Wed/Fri until Friday, then daily from Saturday Sep 26.
        let history = T.history(from: 14, weekdays: T.monWedFri) + [
            SchedulePeriod(effectiveFrom: calendar.startOfDay(for: T.sep(26)), weekdays: Habit.allWeekdays)
        ]
        let completed = T.days(21, 23, 25, 26)

        let streak = HabitProgress.currentStreak(
            completedDays: completed, history: history, today: T.sep(26), calendar: calendar
        )
        #expect(streak == 4)

        // If the new daily schedule applied retroactively, Thu Sep 24 would count as missed.
        let retroactive = HabitProgress.currentStreak(
            completedDays: completed, history: T.history(from: 14), today: T.sep(26), calendar: calendar
        )
        #expect(retroactive == 2)
    }

    // MARK: - Longest streak

    @Test func longestStreakSurvivesAGap() {
        // A 5-day run, a miss on Sep 19, then a 2-day run.
        let completed = T.days(14, 15, 16, 17, 18, 20, 21)
        let history = T.history(from: 14)

        let longest = HabitProgress.longestStreak(
            completedDays: completed, history: history, today: T.sep(22), calendar: calendar
        )
        let current = HabitProgress.currentStreak(
            completedDays: completed, history: history, today: T.sep(22), calendar: calendar
        )
        #expect(longest == 5)
        #expect(current == 2)
    }

    @Test func emptyHistoryHasNoStreak() {
        let streak = HabitProgress.currentStreak(
            completedDays: T.days(25, 26), history: [], today: T.sep(26), calendar: calendar
        )
        #expect(streak == 0)
    }
}
