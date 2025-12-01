//
//  Comment.swift
//  Swipop
//

import Foundation

struct Comment: Identifiable, Codable, Equatable {
    let id: UUID
    let workId: UUID
    let userId: UUID
    var content: String
    var parentId: UUID?
    let createdAt: Date
    
    // Joined data (not persisted)
    var user: CommentUser?
    var replyCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case workId = "work_id"
        case userId = "user_id"
        case content
        case parentId = "parent_id"
        case createdAt = "created_at"
        case user
        case replyCount = "reply_count"
    }
}

struct CommentUser: Codable, Equatable {
    let id: UUID
    let username: String?
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Sample Data

extension Comment {
    static let sample = Comment(
        id: UUID(),
        workId: UUID(),
        userId: UUID(),
        content: "This is amazing! 🔥",
        parentId: nil,
        createdAt: Date(),
        user: CommentUser(
            id: UUID(),
            username: "creator",
            displayName: "Creative Dev",
            avatarUrl: nil
        ),
        replyCount: 2
    )
    
    static let samples: [Comment] = [
        sample,
        Comment(
            id: UUID(),
            workId: UUID(),
            userId: UUID(),
            content: "Love the animation effect!",
            parentId: nil,
            createdAt: Date().addingTimeInterval(-3600),
            user: CommentUser(id: UUID(), username: "user2", displayName: "Designer", avatarUrl: nil),
            replyCount: 0
        ),
        Comment(
            id: UUID(),
            workId: UUID(),
            userId: UUID(),
            content: "How did you make this? Tutorial please!",
            parentId: nil,
            createdAt: Date().addingTimeInterval(-7200),
            user: CommentUser(id: UUID(), username: "learner", displayName: "Learner", avatarUrl: nil),
            replyCount: 5
        )
    ]
}

