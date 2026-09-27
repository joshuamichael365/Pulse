//
//  Constants.swift
//  Pulse
//
//  Created by Joshua Michael on 7/12/26.
//

import SwiftUI

/// Global constants and design tokens for the Pulse app.
enum PulseColors {
    static let accent = Color("AccentColor")
    static let background = Color(dark: Color(hex: "0A0A0F"), light: Color(hex: "F2F2F7"))
    static let surface = Color(dark: Color(hex: "1C1C2E"), light: Color.white)
    static let secondary = Color(dark: Color(hex: "8E8E93"), light: Color(hex: "6B7280"))
    static let text = Color(dark: Color(hex: "F2F2F7"), light: Color(hex: "0A0A0F"))
}

enum PulseSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum PulseRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    init(dark: Color, light: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

enum PulseStrings {
    static let appName = "Pulse"
    static let dashboardTitle = "Home"
    static let checkInTitle = "Check In"
    static let coachTitle = "Coach"
    static let profileTitle = "Profile"
    static let morningGreeting = "Good morning"
    static let afternoonGreeting = "Good afternoon"
    static let eveningGreeting = "Good evening"

    // MARK: Habit presets
    static let presetWater = "Water"
    static let presetReading = "Reading"
    static let presetMeditation = "Meditation"
    static let presetVitamins = "Vitamins"
    static let presetSteps = "Steps"
    static let presetExercise = "Exercise"
    static let presetStretching = "Stretching"
    static let presetOutdoors = "Time outdoors"
    static let presetNoAlcohol = "No alcohol"
    static let presetScreensOff = "Screens off before bed"

    // MARK: Habit errors
    static let habitErrorEmptyName = "Give your habit a name."
    static let habitErrorInvalidTarget = "Target must be greater than zero."
    static let habitErrorDuplicatePreset = "You already have this habit."
    static let habitErrorNoDays = "Pick at least one day."
}
