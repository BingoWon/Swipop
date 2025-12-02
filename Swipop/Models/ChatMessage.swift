//
//  ChatMessage.swift
//  Swipop
//

import Foundation

/// A single message in the chat conversation
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    var reasoning: String = ""
    var toolCall: ToolCallInfo?
    var isStreaming = false
    var isThinking = false
    let timestamp = Date()
    
    /// When thinking started (for duration display)
    var thinkingStartTime: Date?
    /// When thinking ended
    var thinkingEndTime: Date?
    
    enum Role {
        case user
        case assistant
        case error
    }
    
    struct ToolCallInfo {
        let name: String
        let arguments: String
        var result: String?
    }
    
    /// Create an error message
    static func error(_ message: String) -> ChatMessage {
        ChatMessage(role: .error, content: message)
    }
    
    /// Has thinking content to show
    var hasReasoning: Bool { !reasoning.isEmpty }
    
    /// Thinking duration in seconds
    var thinkingDuration: Int? {
        guard let start = thinkingStartTime else { return nil }
        let end = thinkingEndTime ?? Date()
        return Int(end.timeIntervalSince(start))
    }
}

