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
    var toolCall: ToolCallInfo?
    var isStreaming = false
    let timestamp = Date()
    
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
}

