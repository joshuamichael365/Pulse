//
//  ProfileView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI

/// The profile screen for settings, HealthKit permissions, and account management.
struct ProfileView: View {

    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Settings and profile will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
