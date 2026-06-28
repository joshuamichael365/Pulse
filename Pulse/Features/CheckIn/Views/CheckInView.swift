//
//  CheckInView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI
import SwiftData

/// The check-in screen where users log their daily wellness data.
struct CheckInView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CheckInViewModel?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Check In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your check-ins will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Check In")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(context: modelContext)
                viewModel?.fetchCheckIns()
            }
        }
    }
}

#Preview {
    CheckInView()
        .modelContainer(for: [CheckIn.self], inMemory: true)
}
