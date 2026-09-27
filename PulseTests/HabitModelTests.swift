//
//  HabitModelTests.swift
//  PulseTests
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation
import Testing
@testable import Pulse

@MainActor
struct HabitModelTests {

    private let calendar = HabitTestSupport.calendar
    private typealias T = HabitTestSupport

    // MARK: - Units

    @Test(arguments: [
        (HabitUnit.glasses, 1.0),
        (HabitUnit.minutes, 5.0),
        (HabitUnit.pages, 5.0),
        (HabitUnit.times, 1.0),
    ])
    func steppedUnitsHaveAStepSize(unit: HabitUnit, expected: Double) {
        #expect(unit.stepSize == expected)
    }

    @Test func stepsUseTypedEntry() {
        #expect(HabitUnit.steps.stepSize == nil)
    }

    @Test func habitStepSizeComesFromItsUnit() {
        let water = Habit(name: "Water", type: .quantity, unit: .glasses, targetValue: 8)
        let vitamins = Habit(name: "Vitamins")
        #expect(water.stepSize == 1)
        #expect(vitamins.stepSize == nil)
    }

    // MARK: - Schedule history

    @Test func newHabitHasExactlyOnePeriod() {
        let habit = Habit(name: "Read", weekdays: T.monWedFri, startDate: T.sep(14, hour: 15), calendar: calendar)
        #expect(habit.scheduleHistory.count == 1)
        #expect(habit.scheduleHistory[0].effectiveFrom == calendar.startOfDay(for: T.sep(14)))
        #expect(habit.scheduledWeekdays == T.monWedFri)
    }

    @Test func startDateComesFromTheFirstPeriod() {
        let habit = Habit(name: "Read", startDate: T.sep(14), calendar: calendar)
        habit.setSchedule(T.monWedFri, from: T.sep(21), calendar: calendar)
        #expect(habit.startDate == calendar.startOfDay(for: T.sep(14)))
    }

    // Passing empty weekdays to Habit.init or setSchedule is a programming error that
    // asserts in debug builds, so it can't be called from a test. The view model tests
    // cover the guard that stops it from ever reaching the model.

    @Test func weekdaysAreSortedDedupedAndValidated() {
        #expect(Habit.normalized([6, 2, 2, 9, 0, 4]) == [2, 4, 6])
    }

    @Test func normalizingNoValidDaysGivesEmptyNotDaily() {
        #expect(Habit.normalized([]) == [])
        #expect(Habit.normalized([0, 8, 9]) == [])
    }

    @Test func scheduleChangeAddsAPeriodFromThatDay() {
        let habit = Habit(name: "Read", startDate: T.sep(14), calendar: calendar)
        habit.setSchedule(T.monWedFri, from: T.sep(21), calendar: calendar)

        #expect(habit.scheduleHistory.count == 2)
        #expect(habit.scheduleHistory[0].weekdays == Habit.allWeekdays)
        #expect(habit.scheduleHistory[1].effectiveFrom == calendar.startOfDay(for: T.sep(21)))
        #expect(habit.scheduledWeekdays == T.monWedFri)
    }

    @Test func twoChangesOnTheSameDayLeaveOnePeriodForThatDay() {
        let habit = Habit(name: "Read", startDate: T.sep(14), calendar: calendar)
        habit.setSchedule(T.monWedFri, from: T.sep(21, hour: 8), calendar: calendar)
        habit.setSchedule([2, 3], from: T.sep(21, hour: 20), calendar: calendar)

        #expect(habit.scheduleHistory.count == 2)
        #expect(habit.scheduledWeekdays == [2, 3])
    }

    @Test func changeOnTheCreationDayReplacesTheFirstPeriod() {
        let habit = Habit(name: "Read", startDate: T.sep(14), calendar: calendar)
        habit.setSchedule(T.monWedFri, from: T.sep(14, hour: 18), calendar: calendar)

        #expect(habit.scheduleHistory.count == 1)
        #expect(habit.scheduledWeekdays == T.monWedFri)
    }

    @Test func unchangedScheduleAddsNoPeriod() {
        let habit = Habit(name: "Read", weekdays: T.monWedFri, startDate: T.sep(14), calendar: calendar)
        habit.setSchedule([6, 4, 2], from: T.sep(21), calendar: calendar)
        #expect(habit.scheduleHistory.count == 1)
    }

    // MARK: - Presets

    @Test func presetIDsAreUnique() {
        let ids = HabitPresets.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func quantityPresetsHaveAUnitAndPositiveTarget() {
        for preset in HabitPresets.all where preset.type == .quantity {
            #expect(preset.unit != nil, "\(preset.id) is missing a unit")
            #expect((preset.defaultTarget ?? 0) > 0, "\(preset.id) needs a positive target")
        }
    }

    @Test func yesNoPresetsHaveNoUnitOrTarget() {
        for preset in HabitPresets.all where preset.type == .yesNo {
            #expect(preset.unit == nil, "\(preset.id) shouldn't have a unit")
            #expect(preset.defaultTarget == nil, "\(preset.id) shouldn't have a target")
        }
    }
}
