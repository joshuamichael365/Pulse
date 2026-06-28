//
//  DashboardView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI
import SwiftData

/// The main dashboard screen showing today's habits and wellness summary.
struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your habits will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Pulse")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(context: modelContext)
                viewModel?.fetchHabits()
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
