//
//  HabitPresets.swift
//  Pulse
//
//  Created by Joshua Michael on 9/26/26.
//

import Foundation

/// A preconfigured habit in the preset library.
///
/// Everything except the target (and schedule) is fixed. Step size comes from the unit.
struct HabitPreset: Identifiable, Equatable {

    /// A stable identifier saved on habits created from this preset. Never change these.
    let id: String

    /// The display name of the habit.
    let name: String

    /// The emoji used as a visual identifier.
    let emoji: String

    /// The category the habit belongs to.
    let category: HabitCategory

    /// Whether the habit is a yes/no check or an amount toward a target.
    let type: HabitType

    /// The unit for quantity presets. Nil for yes/no presets.
    let unit: HabitUnit?

    /// The starting target for quantity presets. Nil for yes/no presets.
    let defaultTarget: Double?
}

/// The preset habit library.
enum HabitPresets {

    /// Every preset, in the order they're shown in the library.
    static let all: [HabitPreset] = [
        HabitPreset(id: "water", name: PulseStrings.presetWater, emoji: "💧",
                    category: .health, type: .quantity, unit: .glasses, defaultTarget: 8),
        HabitPreset(id: "reading", name: PulseStrings.presetReading, emoji: "📖",
                    category: .productivity, type: .quantity, unit: .minutes, defaultTarget: 20),
        HabitPreset(id: "meditation", name: PulseStrings.presetMeditation, emoji: "🧘",
                    category: .mindfulness, type: .quantity, unit: .minutes, defaultTarget: 10),
        HabitPreset(id: "vitamins", name: PulseStrings.presetVitamins, emoji: "💊",
                    category: .health, type: .yesNo, unit: nil, defaultTarget: nil),
        HabitPreset(id: "steps", name: PulseStrings.presetSteps, emoji: "👟",
                    category: .fitness, type: .quantity, unit: .steps, defaultTarget: 8000),
        HabitPreset(id: "exercise", name: PulseStrings.presetExercise, emoji: "🏋️",
                    category: .fitness, type: .quantity, unit: .minutes, defaultTarget: 30),
        HabitPreset(id: "stretching", name: PulseStrings.presetStretching, emoji: "🤸",
                    category: .fitness, type: .quantity, unit: .minutes, defaultTarget: 10),
        HabitPreset(id: "outdoors", name: PulseStrings.presetOutdoors, emoji: "🌳",
                    category: .mindfulness, type: .quantity, unit: .minutes, defaultTarget: 20),
        HabitPreset(id: "no-alcohol", name: PulseStrings.presetNoAlcohol, emoji: "🚫",
                    category: .health, type: .yesNo, unit: nil, defaultTarget: nil),
        HabitPreset(id: "screens-off", name: PulseStrings.presetScreensOff, emoji: "📵",
                    category: .sleep, type: .yesNo, unit: nil, defaultTarget: nil),
    ]

    /// Looks up a preset by its identifier.
    static func preset(id: String) -> HabitPreset? {
        all.first { $0.id == id }
    }
}
