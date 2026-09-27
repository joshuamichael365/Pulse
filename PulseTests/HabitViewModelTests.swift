//
//  HabitViewModelTests.swift
//  PulseTests
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation
import SwiftData
import Testing
@testable import Pulse

@MainActor
struct HabitViewModelTests {

    private typealias T = HabitTestSupport

    /// Held so the in-memory store lives as long as the test.
    private let container: ModelContainer
    private let context: ModelContext
    private let clock: TestClock
    private let viewModel: HabitViewModel

    init() throws {
        container = try ModelContainer(
            for: Habit.self, HabitLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        let clock = TestClock(T.sep(21)) // Monday
        self.clock = clock
        viewModel = HabitViewModel(context: context, calendar: T.calendar, now: { clock.now })
    }

    private var water: HabitPreset { HabitPresets.preset(id: "water")! }
    private var vitamins: HabitPreset { HabitPresets.preset(id: "vitamins")! }

    private func logCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<HabitLog>())
    }

    // MARK: - Creating

    @Test func everyCreationPathStartsWithOneSchedulePeriod() throws {
        let preset = try #require(viewModel.createFromPreset(water, weekdays: T.monWedFri))
        let custom = try #require(viewModel.createCustom(name: "Floss"))

        for habit in [preset, custom] {
            #expect(habit.scheduleHistory.count == 1)
            #expect(habit.startDate == T.calendar.startOfDay(for: T.sep(21)))
        }
        #expect(preset.scheduledWeekdays == T.monWedFri)
        #expect(custom.scheduledWeekdays == Habit.allWeekdays)
    }

    @Test func presetCopiesItsSettingsAndCustomTarget() throws {
        let habit = try #require(viewModel.createFromPreset(water, target: 10))
        #expect(habit.presetID == "water")
        #expect(habit.type == .quantity)
        #expect(habit.unit == .glasses)
        #expect(habit.targetValue == 10)
    }

    @Test func samePresetCantBeAddedTwice() {
        viewModel.createFromPreset(water)
        #expect(viewModel.createFromPreset(water) == nil)
        #expect(viewModel.errorMessage == PulseStrings.habitErrorDuplicatePreset)
    }

    @Test func customHabitIsYesNoWithATrimmedName() throws {
        let habit = try #require(viewModel.createCustom(name: "  Floss  "))
        #expect(habit.name == "Floss")
        #expect(habit.type == .yesNo)
        #expect(habit.category == .other)
    }

    @Test(arguments: [[Int](), [0, 9]])
    func creatingWithNoValidDaysIsRejected(weekdays: [Int]) throws {
        #expect(viewModel.createCustom(name: "Floss", weekdays: weekdays) == nil)
        #expect(viewModel.errorMessage == PulseStrings.habitErrorNoDays)
        #expect(viewModel.createFromPreset(water, weekdays: weekdays) == nil)
        #expect(try context.fetchCount(FetchDescriptor<Habit>()) == 0)
    }

    @Test func updatingToNoDaysKeepsTheCurrentSchedule() throws {
        let habit = try #require(viewModel.createCustom(name: "Lift", weekdays: T.monWedFri))
        clock.now = T.sep(23)
        viewModel.updateSchedule([], for: habit)

        #expect(viewModel.errorMessage == PulseStrings.habitErrorNoDays)
        #expect(habit.scheduleHistory.count == 1)
        #expect(habit.scheduledWeekdays == T.monWedFri)
    }

    @Test func customHabitNeedsAName() {
        #expect(viewModel.createCustom(name: "   ") == nil)
        #expect(viewModel.errorMessage == PulseStrings.habitErrorEmptyName)
    }

    // MARK: - Yes/no logging

    @Test func togglingTwiceLeavesNoLogs() throws {
        let habit = try #require(viewModel.createFromPreset(vitamins))
        viewModel.toggle(habit)
        #expect(viewModel.isCompletedToday(habit))

        viewModel.toggle(habit)
        #expect(!viewModel.isCompletedToday(habit))
        #expect(try logCount() == 0)
    }

    @Test func toggleIgnoresQuantityHabits() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.toggle(habit)
        #expect(try logCount() == 0)
    }

    // MARK: - Quantity logging

    @Test func addAmountAccumulatesIntoOneLogPerDay() throws {
        let habit = try #require(viewModel.createFromPreset(water)) // target 8
        viewModel.addAmount(3, to: habit)
        viewModel.addAmount(2, to: habit)

        #expect(try logCount() == 1)
        #expect(viewModel.todayLog(for: habit)?.value == 5)
        #expect(viewModel.completionFractionToday(habit) == 5.0 / 8.0)
        #expect(!viewModel.isCompletedToday(habit))

        viewModel.addAmount(3, to: habit)
        #expect(viewModel.isCompletedToday(habit))
        #expect(viewModel.todayLog(for: habit)?.completedAt != nil)
    }

    @Test func eachDayGetsItsOwnLog() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.addAmount(8, to: habit)
        clock.now = T.sep(22)
        viewModel.addAmount(8, to: habit)

        #expect(try logCount() == 2)
        #expect(viewModel.currentStreak(for: habit) == 2)
    }

    @Test func settingZeroRemovesTodaysLog() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.setAmount(4, for: habit)
        viewModel.setAmount(0, for: habit)
        #expect(try logCount() == 0)
    }

    @Test func raisingTheTargetDoesntChangePastDays() throws {
        let habit = try #require(viewModel.createFromPreset(water)) // target 8
        viewModel.addAmount(8, to: habit)                          // Mon: 8 of 8, done

        clock.now = T.sep(22)
        viewModel.updateTarget(10, for: habit)
        viewModel.addAmount(8, to: habit)                          // Tue: 8 of 10, not done

        let monday = try #require(habit.logs.first { T.calendar.isDate($0.date, inSameDayAs: T.sep(21)) })
        #expect(monday.targetAtLog == 8)
        #expect(monday.isComplete)
        #expect(!viewModel.isCompletedToday(habit))
        #expect(viewModel.currentStreak(for: habit) == 1)          // Monday still counts
    }

    @Test func changingTheTargetUpdatesTodaysLog() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.addAmount(8, to: habit)
        #expect(viewModel.isCompletedToday(habit))

        viewModel.updateTarget(10, for: habit)
        #expect(viewModel.todayLog(for: habit)?.targetAtLog == 10)
        #expect(!viewModel.isCompletedToday(habit))
        #expect(viewModel.todayLog(for: habit)?.completedAt == nil)
    }

    // MARK: - Schedule

    @Test func onlyHabitsScheduledTodayShow() throws {
        let everyDay = try #require(viewModel.createFromPreset(vitamins))
        let monWedFri = try #require(viewModel.createCustom(name: "Lift", weekdays: T.monWedFri))

        #expect(viewModel.habitsScheduledToday.map(\.id) == [everyDay.id, monWedFri.id]) // Mon

        clock.now = T.sep(22) // Tue
        #expect(viewModel.habitsScheduledToday.map(\.id) == [everyDay.id])
    }

    @Test func scheduleEditKeepsThePastStreak() throws {
        let habit = try #require(viewModel.createCustom(name: "Lift", weekdays: T.monWedFri))
        for day in [21, 23, 25] { // Mon, Wed, Fri
            clock.now = T.sep(day)
            viewModel.toggle(habit)
        }

        clock.now = T.sep(26) // Sat
        viewModel.updateSchedule(Habit.allWeekdays, for: habit)
        #expect(habit.scheduleHistory.count == 2)
        #expect(viewModel.currentStreak(for: habit) == 3) // Tue and Thu were rest days
    }

    // MARK: - Archiving, deleting, ordering

    @Test func archivedHabitDisappearsFromTodayAndRestores() throws {
        let habit = try #require(viewModel.createFromPreset(vitamins))
        viewModel.archiveHabit(habit)
        #expect(viewModel.habitsScheduledToday.isEmpty)
        #expect(viewModel.archivedHabits.map(\.id) == [habit.id])

        viewModel.restoreHabit(habit)
        #expect(viewModel.habitsScheduledToday.map(\.id) == [habit.id])
        #expect(viewModel.archivedHabits.isEmpty)
    }

    @Test func archivedPresetCantBeAddedAgain() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.archiveHabit(habit)
        #expect(viewModel.createFromPreset(water) == nil)
    }

    @Test func deletingAHabitDeletesItsLogs() throws {
        let habit = try #require(viewModel.createFromPreset(water))
        viewModel.addAmount(8, to: habit)
        clock.now = T.sep(22)
        viewModel.addAmount(4, to: habit)
        #expect(try logCount() == 2)

        viewModel.deleteHabit(habit)
        #expect(try logCount() == 0)
        #expect(viewModel.habits.isEmpty)
    }

    @Test func moveReordersActiveHabits() throws {
        let a = try #require(viewModel.createCustom(name: "A"))
        let b = try #require(viewModel.createCustom(name: "B"))
        let c = try #require(viewModel.createCustom(name: "C"))

        viewModel.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(viewModel.habits.map(\.id) == [c.id, a.id, b.id])
    }
}
