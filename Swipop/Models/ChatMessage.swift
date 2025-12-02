//
//  ChatMessage.swift
//  Swipop

import Foundation

/// A single message in the chat conversation
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var segments: [Segment] = []
    var isStreaming = false
    let timestamp = Date()
    
    enum Role: String {
        case user
        case assistant
        case error
    }
    
    /// A segment of an assistant message - can be thinking, tool call, or content
    /// Segments appear in order and can repeat in any pattern
    enum Segment: Identifiable {
        case thinking(ThinkingSegment)
        case toolCall(ToolCallSegment)
        case content(String)
        
        var id: UUID {
            switch self {
            case .thinking(let info): info.id
            case .toolCall(let info): info.id
            case .content: UUID() // Content doesn't need stable ID
            }
        }
    }
    
    struct ThinkingSegment: Identifiable {
        let id = UUID()
        var text: String = ""
        var startTime: Date?
        var endTime: Date?
        var isActive: Bool = true
        
        var duration: Int? {
            guard let start = startTime else { return nil }
            let end = endTime ?? Date()
            return Int(end.timeIntervalSince(start))
        }
    }
    
    struct ToolCallSegment: Identifiable {
        let id: UUID
        let callId: String
        let name: String
        let arguments: String
        var result: String?
        
        init(callId: String, name: String, arguments: String) {
            self.id = UUID()
            self.callId = callId
            self.name = name
            self.arguments = arguments
        }
    }
    
    // MARK: - Convenience
    
    /// Create a user message
    static func user(_ content: String) -> ChatMessage {
        var msg = ChatMessage(role: .user)
        msg.segments = [.content(content)]
        return msg
    }
    
    /// Create an error message
    static func error(_ content: String) -> ChatMessage {
        var msg = ChatMessage(role: .error)
        msg.segments = [.content(content)]
        return msg
    }
    
    /// Get user message content (for display)
    var userContent: String {
        guard role == .user else { return "" }
        for segment in segments {
            if case .content(let text) = segment { return text }
        }
        return ""
    }
    
    /// Get error content
    var errorContent: String {
        guard role == .error else { return "" }
        for segment in segments {
            if case .content(let text) = segment { return text }
        }
        return ""
    }
    
    /// Check if there's any thinking segment
    var hasThinking: Bool {
        segments.contains { if case .thinking = $0 { return true }; return false }
    }
    
    /// Check if currently in active thinking state
    var isActivelyThinking: Bool {
        for segment in segments {
            if case .thinking(let info) = segment, info.isActive { return true }
        }
        return false
    }
}
