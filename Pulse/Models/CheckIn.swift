//
//  CheckIn.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import SwiftData

/// The type of check-in, either morning or evening.
enum CheckInType: String, Codable {
    case morning, evening
}

/// The user's reported mood during a check-in.
enum Mood: String, Codable {
    case great, good, neutral, low, anxious, tired, stressed, calm, focused
}

/// A single wellness check-in capturing both user-reported and HealthKit data.
///
/// CheckIn is the primary model feeding the RAG corpus. Each entry combines
/// objective biometric data from HealthKit with subjective user-reported data
/// to create a rich, multi-dimensional snapshot of the user's wellbeing.
/// Over time these entries enable the AI coach to surface meaningful
/// cross-domain correlations between habits, health, and mood.
@Model
final class CheckIn {

    /// The unique identifier for this check-in.
    var id: UUID

    /// The date this check-in was recorded.
    var date: Date

    /// Whether this is a morning or evening check-in.
    var type: CheckInType

    // MARK: - User Reported Fields

    /// The user's reported energy level from 1 to 5.
    var energyLevel: Int?

    /// The user's reported stress level from 1 to 5.
    var stressLevel: Int?

    /// The user's reported mood.
    var mood: Mood?

    /// An optional free-text reflection from the user.
    var reflection: String?

    // MARK: - HealthKit Sourced Fields

    /// Total sleep duration in hours sourced from HealthKit.
    var sleepHours: Double?

    /// Deep sleep duration in hours sourced from HealthKit.
    var deepSleepHours: Double?

    /// REM sleep duration in hours sourced from HealthKit.
    var remSleepHours: Double?

    /// Resting heart rate in BPM sourced from HealthKit.
    var restingHeartRate: Double?

    /// Heart rate variability in milliseconds sourced from HealthKit.
    var hrv: Double?

    /// Total step count sourced from HealthKit.
    var steps: Int?

    /// Active calories burned sourced from HealthKit.
    var activeCalories: Double?

    /// Whether a workout was logged via HealthKit.
    var workoutLogged: Bool

    /// The type of workout logged e.g. "Running", "Strength Training".
    var workoutType: String?

    /// Workout duration in minutes sourced from HealthKit.
    var workoutMinutes: Double?

    // MARK: - Nutrition Fields

    /// Total calories consumed sourced from HealthKit or Passio AI.
    var calories: Double?

    /// Total protein consumed in grams.
    var protein: Double?

    /// Total carbohydrates consumed in grams.
    var carbs: Double?

    /// Total fat consumed in grams.
    var fat: Double?

    /// An optional natural language description of meals eaten.
    var mealDescription: String?

    // MARK: - Metadata

    /// The date and time this check-in was created.
    var createdAt: Date

    /// The date and time this check-in was last modified.
    var updatedAt: Date

    /// Creates a new check-in entry.
    ///
    /// - Parameters:
    ///   - date: The date of this check-in. Defaults to now.
    ///   - type: Whether this is a morning or evening check-in.
    ///   - energyLevel: The user's reported energy level from 1 to 5.
    ///   - stressLevel: The user's reported stress level from 1 to 5.
    ///   - mood: The user's reported mood.
    ///   - reflection: An optional free-text reflection.
    init(
        date: Date = Date(),
        type: CheckInType,
        energyLevel: Int? = nil,
        stressLevel: Int? = nil,
        mood: Mood? = nil,
        reflection: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.mood = mood
        self.reflection = reflection
        self.workoutLogged = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
