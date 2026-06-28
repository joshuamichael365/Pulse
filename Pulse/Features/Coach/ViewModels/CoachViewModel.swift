//
//  CoachViewModel.swift
//  Pulse
//
//  Created by Joshua Michael on 6/28/26.
//

import Foundation
import Observation

/// Manages the AI coach chat interface and RAG pipeline interactions.
///
/// CoachViewModel is a placeholder for Phase 3 RAG implementation.
/// It will handle sending user queries through the RAG pipeline,
/// managing conversation history, and displaying AI-generated insights
/// grounded in the user's personal corpus of habits and check-ins.
@Observable
final class CoachViewModel {

    // MARK: - Properties

    /// The conversation history between the user and the AI coach.
    var messages: [CoachMessage] = []

    /// Whether the AI is currently generating a response.
    var isThinking: Bool = false

    /// An error message to display if something goes wrong.
    var errorMessage: String? = nil

    /// The current text in the user's input field.
    var inputText: String = ""

    // MARK: - Init

    init() { }

    // MARK: - Coach Operations

    /// Sends a message to the AI coach and appends the response.
    /// - Parameter message: The user's message text.
    func sendMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = CoachMessage(role: .user, content: message)
        messages.append(userMessage)
        inputText = ""
        isThinking = true

        // RAG pipeline will be implemented in Phase 3
        // For now return a placeholder response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response = CoachMessage(
                role: .assistant,
                content: "I'm Pulse AI. I'll be able to answer questions about your habits and wellness once the RAG pipeline is connected in Phase 3."
            )
            self.messages.append(response)
            self.isThinking = false
        }
    }

    /// Clears the entire conversation history.
    func clearConversation() {
        messages = []
    }
}

/// A single message in the coach conversation.
struct CoachMessage: Identifiable {
    let id: UUID = UUID()
    let role: CoachRole
    let content: String
    let timestamp: Date = Date()
}

/// The role of a message sender in the coach conversation.
enum CoachRole {
    case user, assistant
}
