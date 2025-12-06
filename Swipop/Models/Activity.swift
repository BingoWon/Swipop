//
//  Activity.swift
//  Swipop
//
//  Activity notification model
//

import SwiftUI

struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let actorId: UUID
    let type: ActivityType
    let projectId: UUID?
    let commentId: UUID?
    let isRead: Bool
    let createdAt: Date

    // Joined data
    let actor: Profile?
    let project: Project?

    var timeAgo: String { createdAt.timeAgo }

    // Hashable - only use id for equality/hashing
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case type
        case projectId = "project_id"
        case commentId = "comment_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actor
        case project
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

    func message(actorName: String, projectTitle: String?) -> AttributedString {
        var result: AttributedString

        switch self {
        case .like:
            result = AttributedString("\(actorName) liked your project")
            if let title = projectTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            }
        case .comment:
            result = AttributedString("\(actorName) commented on")
            if let title = projectTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            } else {
                result += AttributedString(" your project")
            }
        case .follow:
            result = AttributedString("\(actorName) started following you")
        case .collect:
            result = AttributedString("\(actorName) saved your project")
            if let title = projectTitle, !title.isEmpty {
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
