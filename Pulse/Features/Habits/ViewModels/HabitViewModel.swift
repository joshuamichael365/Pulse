//
//  HabitViewModel.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData
import Observation

/// Manages all habit-related data and business logic for the Habits feature.
///
/// HabitViewModel acts as the bridge between SwiftData and the Habits UI.
/// It handles creating, updating, archiving, and logging habits, and exposes
/// prepared data for views to display. Streaks and completion are calculated
/// on demand by `HabitProgress`, never stored.
@Observable
final class HabitViewModel {

    // MARK: - Properties

    /// All active habits, in the user's display order.
    var habits: [Habit] = []

    /// All archived habits, most recently archived first.
    var archivedHabits: [Habit] = []

    /// Whether data is currently being loaded.
    var isLoading: Bool = false

    /// An error message to display if something goes wrong.
    var errorMessage: String? = nil

    /// The SwiftData model context used for all database operations.
    private var modelContext: ModelContext

    /// The calendar used for days, weekdays, and streaks.
    private let calendar: Calendar

    /// Returns the current date. Injected so tests can control "today".
    private let now: () -> Date

    // MARK: - Init

    /// Creates a new HabitViewModel with the given SwiftData context.
    /// - Parameters:
    ///   - context: The SwiftData ModelContext for database operations.
    ///   - calendar: The calendar used for days and weekdays. Defaults to the current calendar.
    ///   - now: Returns the current date. Defaults to the system clock.
    init(
        context: ModelContext,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.modelContext = context
        self.calendar = calendar
        self.now = now
    }

    // MARK: - Fetching

    /// Fetches active and archived habits from SwiftData.
    func fetchHabits() {
        let activeDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let archivedDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.archivedAt != nil },
            sortBy: [SortDescriptor(\.archivedAt, order: .reverse)]
        )
        do {
            habits = try modelContext.fetch(activeDescriptor)
            archivedHabits = try modelContext.fetch(archivedDescriptor)
        } catch {
            errorMessage = "Failed to fetch habits: \(error.localizedDescription)"
        }
    }

    /// Active habits scheduled for today.
    var habitsScheduledToday: [Habit] {
        habits.filter {
            HabitProgress.isScheduled(on: now(), history: $0.scheduleHistory, calendar: calendar)
        }
    }

    // MARK: - Progress

    /// The habit's log for today, if there is one.
    func todayLog(for habit: Habit) -> HabitLog? {
        log(for: habit, on: now())
    }

    /// Whether the habit is done for today.
    func isCompletedToday(_ habit: Habit) -> Bool {
        todayLog(for: habit)?.isComplete ?? false
    }

    /// How far today's quantity log is toward its target, from 0 to 1.
    /// Yes/no habits return 1 when done and 0 otherwise.
    func completionFractionToday(_ habit: Habit) -> Double {
        guard let log = todayLog(for: habit) else { return 0 }
        switch habit.type {
        case .yesNo:    return 1
        case .quantity: return HabitProgress.completionFraction(value: log.value, target: log.targetAtLog)
        }
    }

    /// The habit's current streak of consecutive scheduled days completed.
    func currentStreak(for habit: Habit) -> Int {
        HabitProgress.currentStreak(
            completedDays: completedDays(for: habit),
            history: habit.scheduleHistory,
            today: now(),
            calendar: calendar
        )
    }

    /// The habit's longest streak ever.
    func longestStreak(for habit: Habit) -> Int {
        HabitProgress.longestStreak(
            completedDays: completedDays(for: habit),
            history: habit.scheduleHistory,
            today: now(),
            calendar: calendar
        )
    }

    // MARK: - Logging

    /// Marks a yes/no habit done for today, or undoes it if it's already done.
    /// - Parameter habit: The yes/no habit to toggle.
    func toggle(_ habit: Habit) {
        guard habit.type == .yesNo else { return }

        if let log = todayLog(for: habit) {
            modelContext.delete(log)
        } else {
            let log = HabitLog(date: now(), timeOfDay: currentTimeOfDay(), calendar: calendar)
            log.completedAt = now()
            attach(log, to: habit)
        }
        save()
    }

    /// Adds to today's amount for a quantity habit. Negative amounts subtract.
    /// - Parameters:
    ///   - amount: The amount to add, usually the habit's step size.
    ///   - habit: The quantity habit to log.
    func addAmount(_ amount: Double, to habit: Habit) {
        let current = todayLog(for: habit)?.value ?? 0
        setAmount(current + amount, for: habit)
    }

    /// Sets today's amount for a quantity habit, e.g. from typed entry.
    ///
    /// Saves partial amounts. Setting zero or less removes today's log.
    /// - Parameters:
    ///   - amount: The total amount for today.
    ///   - habit: The quantity habit to log.
    func setAmount(_ amount: Double, for habit: Habit) {
        guard habit.type == .quantity else { return }

        let existing = todayLog(for: habit)
        guard amount > 0 else {
            if let existing { modelContext.delete(existing) }
            save()
            return
        }

        let log: HabitLog
        if let existing {
            log = existing
        } else {
            log = HabitLog(date: now(), targetAtLog: habit.targetValue, calendar: calendar)
            attach(log, to: habit)
        }
        log.value = amount
        log.timeOfDay = currentTimeOfDay()
        log.completedAt = log.isComplete ? (log.completedAt ?? now()) : nil
        save()
    }

    // MARK: - Creating

    /// Creates a habit from a preset. Only the target and schedule can differ from the preset.
    /// - Parameters:
    ///   - preset: The preset to create the habit from.
    ///   - target: The target for quantity presets. Defaults to the preset's target.
    ///   - weekdays: Scheduled `Calendar` weekdays. Defaults to every day.
    /// - Returns: The new habit, or nil if the preset is already added, the target is invalid,
    ///   or no weekdays are selected.
    @discardableResult
    func createFromPreset(
        _ preset: HabitPreset,
        target: Double? = nil,
        weekdays: [Int] = Habit.allWeekdays
    ) -> Habit? {
        guard !hasHabit(fromPreset: preset) else {
            errorMessage = PulseStrings.habitErrorDuplicatePreset
            return nil
        }
        guard hasValidDays(weekdays) else { return nil }

        var resolvedTarget: Double? = nil
        if preset.type == .quantity {
            guard let value = target ?? preset.defaultTarget, value > 0 else {
                errorMessage = PulseStrings.habitErrorInvalidTarget
                return nil
            }
            resolvedTarget = value
        }

        let habit = Habit(
            name: preset.name,
            emoji: preset.emoji,
            category: preset.category,
            type: preset.type,
            unit: preset.unit,
            targetValue: resolvedTarget,
            weekdays: weekdays,
            presetID: preset.id,
            startDate: now(),
            calendar: calendar
        )
        insert(habit)
        return habit
    }

    /// Creates a custom yes/no habit with just a name and schedule.
    /// - Parameters:
    ///   - name: The habit's name. Leading and trailing whitespace is trimmed.
    ///   - weekdays: Scheduled `Calendar` weekdays. Defaults to every day.
    /// - Returns: The new habit, or nil if the name is empty or no weekdays are selected.
    @discardableResult
    func createCustom(name: String, weekdays: [Int] = Habit.allWeekdays) -> Habit? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = PulseStrings.habitErrorEmptyName
            return nil
        }
        guard hasValidDays(weekdays) else { return nil }

        let habit = Habit(
            name: trimmed,
            category: .other,
            type: .yesNo,
            weekdays: weekdays,
            startDate: now(),
            calendar: calendar
        )
        insert(habit)
        return habit
    }

    // MARK: - Updating

    /// Renames a custom habit. Preset names are fixed.
    func rename(_ habit: Habit, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard habit.presetID == nil else { return }
        guard !trimmed.isEmpty else {
            errorMessage = PulseStrings.habitErrorEmptyName
            return
        }
        habit.name = trimmed
        habit.updatedAt = now()
        save()
    }

    /// Changes a quantity habit's target from today onward.
    ///
    /// Today's log picks up the new target. Past logs keep the target they were logged
    /// against, so earlier days don't change.
    func updateTarget(_ target: Double, for habit: Habit) {
        guard habit.type == .quantity else { return }
        guard target > 0 else {
            errorMessage = PulseStrings.habitErrorInvalidTarget
            return
        }
        habit.targetValue = target
        habit.updatedAt = now()
        if let log = todayLog(for: habit) {
            log.targetAtLog = target
            log.completedAt = log.isComplete ? (log.completedAt ?? now()) : nil
        }
        save()
    }

    /// Changes a habit's schedule from today onward. Past days keep their old schedule.
    /// An empty schedule is rejected and the current one is kept.
    func updateSchedule(_ weekdays: [Int], for habit: Habit) {
        guard hasValidDays(weekdays) else { return }
        habit.setSchedule(weekdays, from: now(), calendar: calendar)
        save()
    }

    /// Reorders active habits, matching SwiftUI's `onMove` arguments.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var ordered = habits
        let moving = source.map { ordered[$0] }
        for index in source.sorted(by: >) {
            ordered.remove(at: index)
        }
        let insertAt = destination - source.filter { $0 < destination }.count
        ordered.insert(contentsOf: moving, at: insertAt)

        for (index, habit) in ordered.enumerated() {
            habit.sortOrder = index
        }
        save()
        fetchHabits()
    }

    // MARK: - Archiving and Deleting

    /// Archives a habit so it no longer appears in the active list. Its logs are kept.
    /// - Parameter habit: The habit to archive.
    func archiveHabit(_ habit: Habit) {
        habit.archivedAt = now()
        habit.updatedAt = now()
        save()
        fetchHabits()
    }

    /// Restores an archived habit to the end of the active list.
    /// - Parameter habit: The habit to restore.
    func restoreHabit(_ habit: Habit) {
        habit.archivedAt = nil
        habit.sortOrder = nextSortOrder()
        habit.updatedAt = now()
        save()
        fetchHabits()
    }

    /// Deletes a habit permanently from SwiftData, along with all of its logs.
    /// - Parameter habit: The habit to delete.
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        save()
        fetchHabits()
    }

    // MARK: - Helpers

    /// The habit's log for a given day, if there is one.
    private func log(for habit: Habit, on day: Date) -> HabitLog? {
        habit.logs.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    /// The start-of-day dates on which the habit was completed.
    private func completedDays(for habit: Habit) -> Set<Date> {
        Set(habit.logs.filter(\.isComplete).map { calendar.startOfDay(for: $0.date) })
    }

    /// Whether the weekdays contain at least one valid day. Sets `errorMessage` if not.
    private func hasValidDays(_ weekdays: [Int]) -> Bool {
        guard !Habit.normalized(weekdays).isEmpty else {
            errorMessage = PulseStrings.habitErrorNoDays
            return false
        }
        return true
    }

    /// Whether a habit from this preset already exists, active or archived.
    private func hasHabit(fromPreset preset: HabitPreset) -> Bool {
        let presetID: String? = preset.id
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.presetID == presetID })
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Inserts a log and connects it to its habit.
    private func attach(_ log: HabitLog, to habit: Habit) {
        modelContext.insert(log)
        log.habit = habit
    }

    /// Inserts a new habit at the end of the active list and saves.
    private func insert(_ habit: Habit) {
        habit.sortOrder = nextSortOrder()
        modelContext.insert(habit)
        save()
        fetchHabits()
    }

    /// The sort order that places a habit after every active habit.
    private func nextSortOrder() -> Int {
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.archivedAt == nil })
        let active = (try? modelContext.fetch(descriptor)) ?? []
        return (active.map(\.sortOrder).max() ?? -1) + 1
    }

    /// Saves the current SwiftData context.
    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    /// Returns the current time of day based on the injected clock.
    private func currentTimeOfDay() -> TimeOfDay {
        let hour = calendar.component(.hour, from: now())
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }
}
