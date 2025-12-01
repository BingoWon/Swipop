//
//  Conversation.swift
//  Swipop
//
//  Direct message conversation model
//

import Foundation

struct Conversation: Identifiable {
    let id: UUID
    let recipientId: UUID
    let recipientName: String
    let recipientAvatar: String?
    let lastMessage: String
    let lastMessageAt: Date
    let unreadCount: Int
    
    var timeAgo: String { lastMessageAt.timeAgo }
}

// MARK: - Sample Data

extension Conversation {
    static let samples: [Conversation] = [
        Conversation(
            id: UUID(),
            recipientId: UUID(),
            recipientName: "alice",
            recipientAvatar: nil,
            lastMessage: "Love your work! How did you create that effect?",
            lastMessageAt: Date().addingTimeInterval(-300),
            unreadCount: 2
        ),
        Conversation(
            id: UUID(),
            recipientId: UUID(),
            recipientName: "bob",
            recipientAvatar: nil,
            lastMessage: "Thanks for the follow!",
            lastMessageAt: Date().addingTimeInterval(-7200),
            unreadCount: 0
        ),
    ]
}

