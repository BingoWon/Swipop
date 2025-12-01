//
//  Activity.swift
//  Swipop
//
//  Notification activity model
//

import SwiftUI

struct Activity: Identifiable {
    let id: UUID
    let type: ActivityType
    let userId: UUID
    let userName: String
    let userAvatar: String?
    let workId: UUID?
    let workTitle: String?
    let createdAt: Date
    
    var timeAgo: String { createdAt.timeAgo }
}

enum ActivityType: String, Codable {
    case like
    case comment
    case follow
    case collect
    
    var icon: String {
        switch self {
        case .like: "heart.fill"
        case .comment: "message.fill"
        case .follow: "person.badge.plus.fill"
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
    
    func message(userName: String, workTitle: String?) -> String {
        switch self {
        case .like:
            "**\(userName)** liked \"\(workTitle ?? "")\""
        case .comment:
            "**\(userName)** commented on \"\(workTitle ?? "")\""
        case .follow:
            "**\(userName)** started following you"
        case .collect:
            "**\(userName)** saved \"\(workTitle ?? "")\""
        }
    }
}

// MARK: - Sample Data

extension Activity {
    static let samples: [Activity] = [
        Activity(id: UUID(), type: .like, userId: UUID(), userName: "alice", userAvatar: nil, workId: UUID(), workTitle: "Neon Pulse", createdAt: Date().addingTimeInterval(-120)),
        Activity(id: UUID(), type: .comment, userId: UUID(), userName: "bob", userAvatar: nil, workId: UUID(), workTitle: "Particle Storm", createdAt: Date().addingTimeInterval(-900)),
        Activity(id: UUID(), type: .follow, userId: UUID(), userName: "charlie", userAvatar: nil, workId: nil, workTitle: nil, createdAt: Date().addingTimeInterval(-3600)),
        Activity(id: UUID(), type: .collect, userId: UUID(), userName: "diana", userAvatar: nil, workId: UUID(), workTitle: "Gradient Wave", createdAt: Date().addingTimeInterval(-10800)),
    ]
}

