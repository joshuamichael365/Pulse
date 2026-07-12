//
//  CoachView.swift
//  Pulse
//
//  Created by Joshua Michael on 7/12/26.
//

import SwiftUI

struct CoachView: View {

    @State private var viewModel = CoachViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Mesh gradient background
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5, 0.4), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: [
                        Color(hex: "0A0A0F"), Color(hex: "0A0A0F"), Color(hex: "0A0A0F"),
                        Color(hex: "0A0A0F"), Color(hex: "1C1040"), Color(hex: "0A0A0F"),
                        Color(hex: "0A0A0F"), Color(hex: "110D2E"), Color(hex: "0A0A0F")
                    ]
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: - Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: PulseSpacing.sm) {
                                if viewModel.messages.isEmpty {
                                    CoachWelcomeView()
                                } else {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                }

                                if viewModel.isThinking {
                                    ThinkingBubble()
                                }
                            }
                            .padding(.horizontal, PulseSpacing.md)
                            .padding(.vertical, PulseSpacing.lg)
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // MARK: - Input Bar
                    CoachInputBar(viewModel: viewModel)
                }
            }
            .navigationTitle(PulseStrings.coachTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

// MARK: - Welcome View

struct CoachWelcomeView: View {
    var body: some View {
        VStack(spacing: PulseSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(PulseColors.accent)

            Text("Pulse AI Coach")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Ask me anything about your habits, wellness patterns, or how you've been feeling. The more you log, the smarter I get.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulseSpacing.lg)

            // Suggested prompts
            VStack(spacing: PulseSpacing.sm) {
                SuggestedPromptButton(text: "What patterns do you see in my sleep?")
                SuggestedPromptButton(text: "How has my mood been this week?")
                SuggestedPromptButton(text: "Which habits am I most consistent with?")
                SuggestedPromptButton(text: "Add a new habit for me")
            }
            .padding(.horizontal, PulseSpacing.md)
        }
        .padding(.top, PulseSpacing.xxl)
    }
}

// MARK: - Suggested Prompt Button

struct SuggestedPromptButton: View {
    let text: String

    var body: some View {
        Button {
            // Will be wired up when RAG is implemented
        } label: {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PulseSpacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: CoachMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : .white.opacity(0.9))
                .padding(PulseSpacing.md)
                .background(
                    isUser
                    ? PulseColors.accent.opacity(0.8)
                    : Color.white.opacity(0.1)
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Thinking Bubble

struct ThinkingBubble: View {
    @State private var opacity = 0.3

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .opacity(opacity)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                            value: opacity
                        )
                }
            }
            .padding(PulseSpacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))

            Spacer(minLength: 60)
        }
        .onAppear { opacity = 1.0 }
    }
}

// MARK: - Input Bar

struct CoachInputBar: View {
    let viewModel: CoachViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: PulseSpacing.sm) {
            TextField("Ask your coach...", text: Bindable(viewModel).inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(PulseSpacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PulseRadius.lg))

            Button {
                viewModel.sendMessage(viewModel.inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.inputText.isEmpty ? PulseColors.secondary : PulseColors.accent)
            }
            .disabled(viewModel.inputText.isEmpty)
        }
        .padding(.horizontal, PulseSpacing.md)
        .padding(.vertical, PulseSpacing.sm)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    CoachView()
}
