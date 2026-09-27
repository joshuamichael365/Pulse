//
//  DaylightSavingTests.swift
//  PulseTests
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pulse

/// Streaks and day boundaries across the end of daylight saving time in New York.
///
/// On Sunday Nov 1, 2026 clocks fall back from 2:00 to 1:00, so that day is 25 hours long.
/// Code that steps through days by adding 24 hours, instead of calendar days, would drift
/// off local midnight here and miscount. Times between 1:00 and 2:00 on Nov 1 happen twice,
/// so these tests avoid them.
@MainActor
struct DaylightSavingTests {

    private static let newYork: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    private let calendar = DaylightSavingTests.newYork

    /// A local New York time in autumn 2026.
    private func ny(_ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Start-of-day dates, as the view model builds them from logs.
    private func days(_ dates: [(Int, Int)]) -> Set<Date> {
        Set(dates.map { calendar.startOfDay(for: ny($0.0, $0.1)) })
    }

    /// Thu Oct 29 through Tue Nov 3.
    private let throughTheChange = [(10, 29), (10, 30), (10, 31), (11, 1), (11, 2), (11, 3)]

    private var dailyFromOct29: [SchedulePeriod] {
        [SchedulePeriod(effectiveFrom: calendar.startOfDay(for: ny(10, 29)), weekdays: Habit.allWeekdays)]
    }

    @Test func november1IsReallyA25HourDay() {
        // Guards the test itself: if this fails, the other tests aren't crossing a DST change.
        let nov1 = calendar.startOfDay(for: ny(11, 1))
        let nov2 = calendar.startOfDay(for: ny(11, 2))
        #expect(nov2.timeIntervalSince(nov1) == 25 * 60 * 60)
    }

    @Test func streakCountsEveryDayAcrossTheChange() {
        let completed = days(throughTheChange)
        let today = ny(11, 3, 20)

        #expect(HabitProgress.currentStreak(
            completedDays: completed, history: dailyFromOct29, today: today, calendar: calendar
        ) == 6)
        #expect(HabitProgress.longestStreak(
            completedDays: completed, history: dailyFromOct29, today: today, calendar: calendar
        ) == 6)
    }

    @Test func missingTheChangeDayStillBreaksTheStreak() {
        let completed = days(throughTheChange.filter { $0 != (11, 1) })

        #expect(HabitProgress.currentStreak(
            completedDays: completed, history: dailyFromOct29, today: ny(11, 3, 20), calendar: calendar
        ) == 2)
        #expect(HabitProgress.longestStreak(
            completedDays: completed, history: dailyFromOct29, today: ny(11, 3, 20), calendar: calendar
        ) == 3)
    }

    @Test func weekdayLookupHoldsAtBothEndsOfTheLongDay() {
        // Sunday-only habit (Calendar weekday 1).
        let sundays = [SchedulePeriod(effectiveFrom: calendar.startOfDay(for: ny(10, 25)), weekdays: [1])]

        #expect(HabitProgress.isScheduled(on: ny(11, 1, 0, 30), history: sundays, calendar: calendar))
        #expect(HabitProgress.isScheduled(on: ny(11, 1, 23, 30), history: sundays, calendar: calendar))
        #expect(!HabitProgress.isScheduled(on: ny(11, 2, 0, 30), history: sundays, calendar: calendar))
        #expect(!HabitProgress.isScheduled(on: ny(10, 31, 23, 30), history: sundays, calendar: calendar))
    }

    @Test func lateNightLogsLandOnTheirOwnDays() throws {
        let container = try ModelContainer(
            for: Habit.self, HabitLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let clock = TestClock(ny(10, 30, 23, 30))
        let viewModel = HabitViewModel(context: container.mainContext, calendar: calendar, now: { clock.now })
        let habit = try #require(viewModel.createCustom(name: "Floss"))

        // Log at 11:30 PM every night, Fri Oct 30 through Mon Nov 2.
        for (month, day) in [(10, 30), (10, 31), (11, 1), (11, 2)] {
            clock.now = ny(month, day, 23, 30)
            viewModel.toggle(habit)
        }

        let logDays = habit.logs.map(\.date).sorted()
        #expect(logDays.count == 4)
        #expect(logDays == [(10, 30), (10, 31), (11, 1), (11, 2)].map { calendar.startOfDay(for: ny($0.0, $0.1)) })
        #expect(viewModel.currentStreak(for: habit) == 4)
    }

    @Test func bothEndsOfTheLongDayShareOneLog() throws {
        let container = try ModelContainer(
            for: Habit.self, HabitLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let clock = TestClock(ny(11, 1, 0, 30))
        let viewModel = HabitViewModel(context: container.mainContext, calendar: calendar, now: { clock.now })
        let water = try #require(viewModel.createFromPreset(HabitPresets.preset(id: "water")!))

        viewModel.addAmount(3, to: water)   // 12:30 AM, before the clocks fall back
        clock.now = ny(11, 1, 23, 30)
        viewModel.addAmount(5, to: water)   // 11:30 PM, after

        #expect(water.logs.count == 1)
        #expect(viewModel.todayLog(for: water)?.value == 8)
        #expect(viewModel.isCompletedToday(water))
    }
}
