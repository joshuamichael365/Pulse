//
//  CheckInViewModel.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData
import Observation

/// Manages all check-in related data and business logic for the CheckIn feature.
///
/// CheckInViewModel handles creating and fetching check-in entries,
/// and prepares data for the check-in UI flow. It also coordinates
/// with HealthKit to populate objective biometric fields automatically.
@Observable
final class CheckInViewModel {

    // MARK: - Properties

    /// All check-ins fetched from SwiftData, sorted by date descending.
    var checkIns: [CheckIn] = []

    /// Whether data is currently being loaded.
    var isLoading: Bool = false

    /// An error message to display if something goes wrong.
    var errorMessage: String? = nil

    /// Whether the morning check-in has been completed today.
    var morningCheckInDone: Bool = false

    /// Whether the evening check-in has been completed today.
    var eveningCheckInDone: Bool = false

    /// The SwiftData model context used for all database operations.
    private var modelContext: ModelContext

    // MARK: - Init

    /// Creates a new CheckInViewModel with the given SwiftData context.
    /// - Parameter context: The SwiftData ModelContext for database operations.
    init(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - CheckIn Operations

    /// Fetches all check-ins from SwiftData sorted by date descending.
    func fetchCheckIns() {
        let descriptor = FetchDescriptor<CheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            checkIns = try modelContext.fetch(descriptor)
            updateTodayStatus()
        } catch {
            errorMessage = "Failed to fetch check-ins: \(error.localizedDescription)"
        }
    }

    /// Creates and saves a new check-in entry.
    /// - Parameters:
    ///   - type: Whether this is a morning or evening check-in.
    ///   - energyLevel: The user's reported energy level from 1 to 5.
    ///   - stressLevel: The user's reported stress level from 1 to 5.
    ///   - mood: The user's reported mood.
    ///   - reflection: An optional free-text reflection.
    func createCheckIn(
        type: CheckInType,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        mood: Mood? = nil,
        reflection: String? = nil
    ) {
        let checkIn = CheckIn(
            date: Date(),
            type: type,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            mood: mood,
            reflection: reflection
        )
        modelContext.insert(checkIn)
        save()
        fetchCheckIns()
    }

    /// Returns all check-ins for a specific date.
    /// - Parameter date: The date to filter by.
    /// - Returns: An array of check-ins for that date.
    func checkIns(for date: Date) -> [CheckIn] {
        let calendar = Calendar.current
        return checkIns.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    /// Returns the most recent check-in of a given type.
    /// - Parameter type: The check-in type to filter by.
    /// - Returns: The most recent check-in of that type, if any.
    func latestCheckIn(of type: CheckInType) -> CheckIn? {
        checkIns.first { $0.type == type }
    }

    // MARK: - Helpers

    /// Updates the morning and evening completion status for today.
    private func updateTodayStatus() {
        let todayCheckIns = checkIns(for: Date())
        morningCheckInDone = todayCheckIns.contains { $0.type == .morning }
        eveningCheckInDone = todayCheckIns.contains { $0.type == .evening }
    }

    /// Saves the current SwiftData context.
    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
