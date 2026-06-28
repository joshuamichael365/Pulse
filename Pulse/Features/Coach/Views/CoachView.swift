//
//  CoachView.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import SwiftUI

/// The AI coach screen where users interact with the RAG-powered assistant.
struct CoachView: View {

    @State private var viewModel = CoachViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Text("Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your AI coach will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Coach")
        }
    }
}

#Preview {
    CoachView()
}
