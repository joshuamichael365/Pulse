//
//  DashboardView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?
    @State private var currentTime = Date()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        let name = "Joshua"
        switch hour {
        case 5..<12:  return "\(PulseStrings.morningGreeting), \(name) 👋"
        case 12..<17: return "\(PulseStrings.afternoonGreeting), \(name) 👋"
        default:      return "\(PulseStrings.eveningGreeting), \(name) 👋"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(PulseColors.background)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: PulseSpacing.lg) {

                        // MARK: - Header
                        VStack(alignment: .leading, spacing: PulseSpacing.xs) {
                            Text(greeting)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(PulseColors.text)

                            Text(dateString)
                                .font(.subheadline)
                                .foregroundStyle(PulseColors.secondary)
                        }
                        .padding(.horizontal, PulseSpacing.md)
                        .padding(.top, PulseSpacing.sm)

                        // MARK: - Check In Prompt
                        CheckInPromptCard()

                        // MARK: - Today's Habits
                        VStack(alignment: .leading, spacing: PulseSpacing.sm) {
                            Text("Today's Habits")
                                .font(.headline)
                                .foregroundStyle(PulseColors.text)
                                .padding(.horizontal, PulseSpacing.md)

                            if let vm = viewModel {
                                if vm.habits.isEmpty {
                                    EmptyHabitsCard()
                                } else {
                                    ForEach(vm.habits) { habit in
                                        HabitCard(habit: habit, viewModel: vm)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }

                        // MARK: - AI Insight Card
                        AIInsightCard()

                    }
                    .padding(.bottom, PulseSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // notifications
                    } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(PulseColors.accent)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(context: modelContext)
                viewModel?.fetchHabits()
            }
        }
    }
}

// MARK: - Check In Prompt Card

struct CheckInPromptCard: View {
    private var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < 12
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: PulseSpacing.xs) {
                Text(isMorning ? "Morning Check-in" : "Evening Check-in")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(PulseColors.text)
                Text("How are you feeling today?")
                    .font(.caption)
                    .foregroundStyle(PulseColors.secondary)
            }
            Spacer()
            Image(systemName: isMorning ? "sun.rise.fill" : "moon.stars.fill")
                .foregroundStyle(PulseColors.accent)
                .font(.title2)
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @State private var isCompleted = false

    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            Text(habit.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(PulseColors.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: PulseRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(PulseColors.text)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(PulseColors.accent)
                    Text("\(habit.streak) day streak")
                        .font(.caption)
                        .foregroundStyle(PulseColors.secondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isCompleted.toggle()
                    if isCompleted {
                        viewModel.markHabitComplete(habit)
                    }
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? PulseColors.accent : PulseColors.secondary)
            }
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

// MARK: - Empty Habits Card

struct EmptyHabitsCard: View {
    var body: some View {
        VStack(spacing: PulseSpacing.sm) {
            Image(systemName: "plus.circle")
                .font(.largeTitle)
                .foregroundStyle(PulseColors.accent)
            Text("No habits yet")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(PulseColors.text)
            Text("Add your first habit to get started")
                .font(.caption)
                .foregroundStyle(PulseColors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(PulseSpacing.xl)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(PulseColors.accent)
                Text("Pulse Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(PulseColors.text)
            }
            Text("Keep logging your habits and check-ins — your personalised insights will appear here once the AI has enough data to work with.")
                .font(.caption)
                .foregroundStyle(PulseColors.secondary)
                .lineSpacing(4)
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
