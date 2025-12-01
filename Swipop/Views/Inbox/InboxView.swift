//
//  InboxView.swift
//  Swipop
//
//  Notifications and messages center
//

import SwiftUI

struct InboxView: View {
    
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("", selection: $selectedSegment) {
                    Text("Activity").tag(0)
                    Text("Messages").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Content
                if selectedSegment == 0 {
                    activityList
                } else {
                    messagesList
                }
            }
            .background(Color.black)
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Activity List
    
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sampleActivities) { activity in
                    ActivityRow(activity: activity)
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .overlay {
            if sampleActivities.isEmpty {
                ContentUnavailableView {
                    Label("No Activity", systemImage: "bell.slash")
                } description: {
                    Text("When someone interacts with your works, you'll see it here.")
                }
            }
        }
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sampleConversations) { conversation in
                    ConversationRow(conversation: conversation)
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .overlay {
            if sampleConversations.isEmpty {
                ContentUnavailableView {
                    Label("No Messages", systemImage: "message.slash")
                } description: {
                    Text("Direct messages from other creators will appear here.")
                }
            }
        }
    }
    
    // MARK: - Sample Data
    
    private var sampleActivities: [Activity] {
        [
            Activity(id: UUID(), type: .like, userName: "alice", userAvatar: nil, workTitle: "Neon Pulse", timeAgo: "2m"),
            Activity(id: UUID(), type: .comment, userName: "bob", userAvatar: nil, workTitle: "Particle Storm", timeAgo: "15m"),
            Activity(id: UUID(), type: .follow, userName: "charlie", userAvatar: nil, workTitle: nil, timeAgo: "1h"),
            Activity(id: UUID(), type: .collect, userName: "diana", userAvatar: nil, workTitle: "Gradient Wave", timeAgo: "3h"),
        ]
    }
    
    private var sampleConversations: [Conversation] {
        [
            Conversation(id: UUID(), userName: "alice", userAvatar: nil, lastMessage: "Love your work! How did you create that effect?", timeAgo: "5m", unreadCount: 2),
            Conversation(id: UUID(), userName: "bob", userAvatar: nil, lastMessage: "Thanks for the follow!", timeAgo: "2h", unreadCount: 0),
        ]
    }
}

// MARK: - Models

private struct Activity: Identifiable {
    let id: UUID
    let type: ActivityType
    let userName: String
    let userAvatar: String?
    let workTitle: String?
    let timeAgo: String
}

private enum ActivityType {
    case like, comment, follow, collect
    
    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.right.fill"
        case .follow: return "person.badge.plus"
        case .collect: return "bookmark.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .like: return .red
        case .comment: return .blue
        case .follow: return .purple
        case .collect: return .yellow
        }
    }
    
    func message(userName: String, workTitle: String?) -> String {
        switch self {
        case .like: return "**\(userName)** liked your work \"\(workTitle ?? "")\""
        case .comment: return "**\(userName)** commented on \"\(workTitle ?? "")\""
        case .follow: return "**\(userName)** started following you"
        case .collect: return "**\(userName)** saved \"\(workTitle ?? "")\""
        }
    }
}

private struct Conversation: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String?
    let lastMessage: String
    let timeAgo: String
    let unreadCount: Int
}

// MARK: - Row Views

private struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(activity.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.message(userName: activity.userName, workTitle: activity.workTitle))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(activity.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.userName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(conversation.userName)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(conversation.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "a855f7"))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    InboxView()
        .preferredColorScheme(.dark)
}

