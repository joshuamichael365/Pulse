//
//  ProfileView.swift
//  Pulse
//
//  Created by Joshua Michael on 7/12/26.
//

import SwiftUI

struct ProfileView: View {

    @State private var notificationsEnabled = true
    @State private var morningTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var eveningTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var useOnDeviceAI = false
    @State private var healthKitConnected = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(PulseColors.background)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: PulseSpacing.lg) {

                        // MARK: - Profile Header
                        ProfileHeaderCard()

                        // MARK: - Stats
                        ProfileStatsCard()

                        // MARK: - HealthKit
                        SettingsSection(title: "Health Data") {
                            SettingsToggleRow(
                                icon: "heart.fill",
                                iconColor: .red,
                                title: "Connect Apple Health",
                                subtitle: "Sync sleep, HRV, steps and more",
                                isOn: $healthKitConnected
                            )
                        }

                        // MARK: - Notifications
                        SettingsSection(title: "Notifications") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                iconColor: PulseColors.accent,
                                title: "Check-in Reminders",
                                subtitle: "Get reminded to log your check-ins",
                                isOn: $notificationsEnabled
                            )

                            if notificationsEnabled {
                                SettingsTimeRow(
                                    icon: "sun.rise.fill",
                                    iconColor: .orange,
                                    title: "Morning",
                                    time: $morningTime
                                )

                                SettingsTimeRow(
                                    icon: "moon.stars.fill",
                                    iconColor: .indigo,
                                    title: "Evening",
                                    time: $eveningTime
                                )
                            }
                        }

                        // MARK: - AI Settings
                        SettingsSection(title: "AI & Privacy") {
                            SettingsToggleRow(
                                icon: "iphone",
                                iconColor: .green,
                                title: "On-Device AI",
                                subtitle: "Process insights locally — no data leaves your device",
                                isOn: $useOnDeviceAI
                            )
                        }

                        // MARK: - About
                        SettingsSection(title: "About") {
                            SettingsLinkRow(
                                icon: "info.circle.fill",
                                iconColor: .blue,
                                title: "Version",
                                value: "1.0.0"
                            )
                            SettingsLinkRow(
                                icon: "lock.shield.fill",
                                iconColor: .green,
                                title: "Privacy Policy",
                                value: ""
                            )
                        }
                    }
                    .padding(.bottom, PulseSpacing.xl)
                }
            }
            .navigationTitle(PulseStrings.profileTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            ZStack {
                Circle()
                    .fill(PulseColors.accent.opacity(0.2))
                    .frame(width: 64, height: 64)
                Text("J")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(PulseColors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Joshua Michael")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(PulseColors.text)
                Text("Pulse Member")
                    .font(.caption)
                    .foregroundStyle(PulseColors.secondary)
            }

            Spacer()
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
        .padding(.top, PulseSpacing.sm)
    }
}

// MARK: - Profile Stats Card

struct ProfileStatsCard: View {
    var body: some View {
        HStack {
            StatItem(value: "0", label: "Day Streak")
            Divider().frame(height: 40)
            StatItem(value: "0", label: "Check-ins")
            Divider().frame(height: 40)
            StatItem(value: "0", label: "Habits")
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(PulseColors.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(PulseColors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PulseColors.text)
                .padding(.horizontal, PulseSpacing.md)

            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
            .padding(.horizontal, PulseSpacing.md)
        }
    }
}

// MARK: - Settings Rows

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(PulseColors.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PulseColors.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(PulseColors.accent)
                .labelsHidden()
        }
        .padding(PulseSpacing.md)
    }
}

struct SettingsTimeRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var time: Date

    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(PulseColors.text)

            Spacer()

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(PulseColors.accent)
        }
        .padding(PulseSpacing.md)
        .overlay(
            Divider()
                .padding(.leading, 52),
            alignment: .top
        )
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(PulseColors.text)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(PulseColors.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(PulseColors.secondary)
        }
        .padding(PulseSpacing.md)
        .overlay(
            Divider()
                .padding(.leading, 52),
            alignment: .top
        )
    }
}

#Preview {
    ProfileView()
}
