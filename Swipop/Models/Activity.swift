//
//  Activity.swift
//  Swipop
//
//  Activity notification model
//

import SwiftUI

struct Activity: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let actorId: UUID
    let type: ActivityType
    let workId: UUID?
    let commentId: UUID?
    let isRead: Bool
    let createdAt: Date
    
    // Joined data
    let actor: Profile?
    let work: Work?
    
    var timeAgo: String { createdAt.timeAgo }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case type
        case workId = "work_id"
        case commentId = "comment_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actor
        case work
    }
}

enum ActivityType: String, Codable {
    case like
    case comment
    case follow
    case collect
    
    var icon: String {
        switch self {
        case .like: "heart.fill"
        case .comment: "bubble.right.fill"
        case .follow: "person.badge.plus"
        case .collect: "bookmark.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .like: .red
        case .comment: .blue
        case .follow: .purple
        case .collect: .yellow
        }
    }
    
    func message(actorName: String, workTitle: String?) -> AttributedString {
        var result: AttributedString
        
        switch self {
        case .like:
            result = AttributedString("\(actorName) liked your work")
            if let title = workTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            }
        case .comment:
            result = AttributedString("\(actorName) commented on")
            if let title = workTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            } else {
                result += AttributedString(" your work")
            }
        case .follow:
            result = AttributedString("\(actorName) started following you")
        case .collect:
            result = AttributedString("\(actorName) saved your work")
            if let title = workTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            }
        }
        
        // Bold the actor name
        if let range = result.range(of: actorName) {
            result[range].font = .system(size: 14, weight: .semibold)
        }
        
        return result
    }
}
