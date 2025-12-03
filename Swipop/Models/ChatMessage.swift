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
    enum Segment: Identifiable {
        case thinking(ThinkingSegment)
        case toolCall(ToolCallSegment)
        case content(String)
        
        var id: UUID {
            switch self {
            case .thinking(let info): info.id
            case .toolCall(let info): info.id
            case .content: UUID()
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
        var arguments: String
        var result: String?
        var isStreaming: Bool
        
        init(callId: String, name: String, arguments: String = "", isStreaming: Bool = false) {
            self.id = UUID()
            self.callId = callId
            self.name = name
            self.arguments = arguments
            self.isStreaming = isStreaming
        }
    }
    
    // MARK: - Convenience
    
    static func user(_ content: String) -> ChatMessage {
        var msg = ChatMessage(role: .user)
        msg.segments = [.content(content)]
        return msg
    }
    
    static func error(_ content: String) -> ChatMessage {
        var msg = ChatMessage(role: .error)
        msg.segments = [.content(content)]
        return msg
    }
    
    var userContent: String {
        guard role == .user else { return "" }
        for segment in segments {
            if case .content(let text) = segment { return text }
        }
        return ""
    }
    
    var errorContent: String {
        guard role == .error else { return "" }
        for segment in segments {
            if case .content(let text) = segment { return text }
        }
        return ""
    }
    
    var hasThinking: Bool {
        segments.contains { if case .thinking = $0 { return true }; return false }
    }
    
    var isActivelyThinking: Bool {
        for segment in segments {
            if case .thinking(let info) = segment, info.isActive { return true }
        }
        return false
    }
    
    /// Check if any tool call is currently streaming
    var hasStreamingToolCall: Bool {
        for segment in segments {
            if case .toolCall(let info) = segment, info.isStreaming { return true }
        }
        return false
    }
}
