//
//  CheckInView.swift
//  Pulse
//
//  Created by Joshua Michael on 7/12/26.
//

import SwiftUI
import SwiftData

struct CheckInView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CheckInViewModel?
    @State private var showingCheckInFlow = false

    private var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < 12
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(PulseColors.background)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: PulseSpacing.lg) {

                        // MARK: - Check In Button
                        CheckInTriggerCard(
                            isMorning: isMorning,
                            isDone: isMorning ? (viewModel?.morningCheckInDone ?? false) : (viewModel?.eveningCheckInDone ?? false)
                        ) {
                            showingCheckInFlow = true
                        }

                        // MARK: - History
                        VStack(alignment: .leading, spacing: PulseSpacing.sm) {
                            Text("Recent Check-ins")
                                .font(.headline)
                                .foregroundStyle(PulseColors.text)
                                .padding(.horizontal, PulseSpacing.md)

                            if let vm = viewModel {
                                if vm.checkIns.isEmpty {
                                    EmptyCheckInsCard()
                                } else {
                                    ForEach(vm.checkIns.prefix(10)) { checkIn in
                                        CheckInHistoryCard(checkIn: checkIn)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, PulseSpacing.xl)
                }
            }
            .navigationTitle(PulseStrings.checkInTitle)
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCheckInFlow) {
            CheckInFlowView(
                type: isMorning ? .morning : .evening,
                viewModel: viewModel
            )
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(context: modelContext)
                viewModel?.fetchCheckIns()
            }
        }
    }
}

// MARK: - Check In Trigger Card

struct CheckInTriggerCard: View {
    let isMorning: Bool
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: PulseSpacing.xs) {
                    Text(isMorning ? "Morning Check-in" : "Evening Check-in")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(PulseColors.text)
                    Text(isDone ? "Completed today ✓" : "Tap to check in")
                        .font(.subheadline)
                        .foregroundStyle(isDone ? PulseColors.accent : PulseColors.secondary)
                }
                Spacer()
                Image(systemName: isDone ? "checkmark.circle.fill" : (isMorning ? "sun.rise.fill" : "moon.stars.fill"))
                    .font(.largeTitle)
                    .foregroundStyle(isDone ? PulseColors.accent : PulseColors.secondary)
            }
            .padding(PulseSpacing.lg)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PulseRadius.xl))
            .padding(.horizontal, PulseSpacing.md)
            .padding(.top, PulseSpacing.sm)
        }
        .disabled(isDone)
    }
}

// MARK: - Check In Flow View

struct CheckInFlowView: View {
    let type: CheckInType
    let viewModel: CheckInViewModel?

    @Environment(\.dismiss) private var dismiss
    @State private var energyLevel: Int = 3
    @State private var stressLevel: Int = 3
    @State private var selectedMood: Mood? = nil
    @State private var reflection: String = ""
    @State private var currentStep = 0

    private let totalSteps = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Color(PulseColors.background)
                    .ignoresSafeArea()

                VStack(spacing: PulseSpacing.lg) {

                    // Progress bar
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .tint(PulseColors.accent)
                        .padding(.horizontal, PulseSpacing.md)

                    // Steps
                    Group {
                        if currentStep == 0 {
                            MoodStepView(selectedMood: $selectedMood)
                        } else if currentStep == 1 {
                            EnergyStressStepView(
                                energyLevel: $energyLevel,
                                stressLevel: $stressLevel
                            )
                        } else {
                            ReflectionStepView(reflection: $reflection, type: type)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

                    Spacer()

                    // Navigation buttons
                    HStack(spacing: PulseSpacing.md) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation { currentStep -= 1 }
                            }
                            .foregroundStyle(PulseColors.secondary)
                        }

                        Spacer()

                        Button(currentStep == totalSteps - 1 ? "Save" : "Next") {
                            if currentStep == totalSteps - 1 {
                                saveCheckIn()
                            } else {
                                withAnimation { currentStep += 1 }
                            }
                        }
                        .padding(.horizontal, PulseSpacing.lg)
                        .padding(.vertical, PulseSpacing.sm)
                        .background(PulseColors.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.md))
                    }
                    .padding(.horizontal, PulseSpacing.md)
                    .padding(.bottom, PulseSpacing.lg)
                }
            }
            .navigationTitle(type == .morning ? "Morning Check-in" : "Evening Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PulseColors.secondary)
                }
            }
        }
    }

    private func saveCheckIn() {
        viewModel?.createCheckIn(
            type: type,
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            mood: selectedMood,
            reflection: reflection.isEmpty ? nil : reflection
        )
        dismiss()
    }
}

// MARK: - Mood Step

struct MoodStepView: View {
    @Binding var selectedMood: Mood?

    let moods: [(Mood, String, String)] = [
        (.great, "😄", "Great"),
        (.good, "🙂", "Good"),
        (.calm, "😌", "Calm"),
        (.neutral, "😐", "Neutral"),
        (.tired, "😴", "Tired"),
        (.stressed, "😰", "Stressed"),
        (.anxious, "😟", "Anxious"),
        (.low, "😔", "Low")
    ]

    var body: some View {
        VStack(spacing: PulseSpacing.lg) {
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(PulseColors.text)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: PulseSpacing.md) {
                ForEach(moods, id: \.0) { mood, emoji, label in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack(spacing: PulseSpacing.xs) {
                            Text(emoji)
                                .font(.largeTitle)
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(PulseColors.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(PulseSpacing.sm)
                        .background(selectedMood == mood ? PulseColors.accent.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: PulseRadius.md)
                                .stroke(selectedMood == mood ? PulseColors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, PulseSpacing.md)
        }
        .padding(.top, PulseSpacing.lg)
    }
}

// MARK: - Energy & Stress Step

struct EnergyStressStepView: View {
    @Binding var energyLevel: Int
    @Binding var stressLevel: Int

    var body: some View {
        VStack(spacing: PulseSpacing.xl) {
            Text("Energy & Stress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(PulseColors.text)

            SliderRowView(
                title: "Energy",
                icon: "bolt.fill",
                value: $energyLevel,
                color: .yellow
            )

            SliderRowView(
                title: "Stress",
                icon: "brain.head.profile",
                value: $stressLevel,
                color: .red
            )
        }
        .padding(.horizontal, PulseSpacing.md)
        .padding(.top, PulseSpacing.lg)
    }
}

struct SliderRowView: View {
    let title: String
    let icon: String
    @Binding var value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PulseColors.text)
                Spacer()
                Text("\(value)/5")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(PulseColors.accent)
            }

            HStack(spacing: PulseSpacing.sm) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        value = level
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level <= value ? color : PulseColors.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
    }
}

// MARK: - Reflection Step

struct ReflectionStepView: View {
    @Binding var reflection: String
    let type: CheckInType

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpacing.lg) {
            Text(type == .morning ? "Set an intention" : "Reflect on your day")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(PulseColors.text)

            Text(type == .morning ? "What do you want to focus on today?" : "How did today go? What's on your mind?")
                .font(.subheadline)
                .foregroundStyle(PulseColors.secondary)

            TextEditor(text: $reflection)
                .frame(minHeight: 150)
                .padding(PulseSpacing.sm)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
                .foregroundStyle(PulseColors.text)
        }
        .padding(.horizontal, PulseSpacing.md)
        .padding(.top, PulseSpacing.lg)
    }
}

// MARK: - Check In History Card

struct CheckInHistoryCard: View {
    let checkIn: CheckIn

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: checkIn.date)
    }

    var body: some View {
        HStack(spacing: PulseSpacing.md) {
            Image(systemName: checkIn.type == .morning ? "sun.rise.fill" : "moon.stars.fill")
                .foregroundStyle(PulseColors.accent)
                .font(.title3)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.type == .morning ? "Morning" : "Evening")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(PulseColors.text)
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(PulseColors.secondary)
            }

            Spacer()

            if let mood = checkIn.mood {
                Text(moodEmoji(mood))
                    .font(.title3)
            }

            if let energy = checkIn.energyLevel {
                VStack(spacing: 0) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("\(energy)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(PulseColors.text)
                }
            }
        }
        .padding(PulseSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }

    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .great: return "😄"
        case .good: return "🙂"
        case .calm: return "😌"
        case .neutral: return "😐"
        case .tired: return "😴"
        case .stressed: return "😰"
        case .anxious: return "😟"
        case .low: return "😔"
        case .focused: return "🎯"
        }
    }
}

// MARK: - Empty Check Ins Card

struct EmptyCheckInsCard: View {
    var body: some View {
        VStack(spacing: PulseSpacing.sm) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
                .foregroundStyle(PulseColors.accent)
            Text("No check-ins yet")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(PulseColors.text)
            Text("Complete your first check-in above")
                .font(.caption)
                .foregroundStyle(PulseColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(PulseSpacing.xl)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        .padding(.horizontal, PulseSpacing.md)
    }
}

#Preview {
    CheckInView()
        .modelContainer(for: [CheckIn.self], inMemory: true)
}
