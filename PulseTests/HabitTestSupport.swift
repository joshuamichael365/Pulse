//
//  HabitTestSupport.swift
//  PulseTests
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation
@testable import Pulse

/// Shared fixtures for habit tests: a fixed calendar and readable dates.
///
/// Weekdays in September 2026 for reference: Mon 14, 21, 28 · Wed 16, 23, 30 ·
/// Fri 18, 25 · Sat 19, 26 · Sun 20, 27.
enum HabitTestSupport {

    /// A Gregorian calendar in UTC, so tests don't depend on the machine's time zone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// `Calendar` weekday numbers.
    static let monWedFri = [2, 4, 6]

    /// A date in September 2026 at the given hour.
    static func sep(_ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    /// Start-of-day dates in September 2026, for `completedDays` sets.
    static func days(_ days: Int...) -> Set<Date> {
        Set(days.map { calendar.startOfDay(for: sep($0)) })
    }

    /// A single-period schedule history starting on the given September day.
    static func history(from day: Int, weekdays: [Int] = Habit.allWeekdays) -> [SchedulePeriod] {
        [SchedulePeriod(effectiveFrom: calendar.startOfDay(for: sep(day)), weekdays: weekdays)]
    }
}

/// A controllable clock for view model tests.
final class TestClock {
    var now: Date

    init(_ now: Date) {
        self.now = now
    }
}
