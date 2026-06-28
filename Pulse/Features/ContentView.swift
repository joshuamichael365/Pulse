//
//  ContentView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI
import SwiftData

/// The root view of the Pulse app.
///
/// ContentView sets up the main tab navigation structure.
/// It serves as the entry point for all four primary features:
/// Dashboard, CheckIn, Coach, and Profile.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CheckInView()
                .tabItem {
                    Label("Check In", systemImage: "heart.fill")
                }

            CoachView()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitLog.self, CheckIn.self, Reflection.self], inMemory: true)
}
