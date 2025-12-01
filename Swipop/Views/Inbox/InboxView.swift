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
                Picker("", selection: $selectedSegment) {
                    Text("Activity").tag(0)
                    Text("Messages").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
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
                ForEach(Activity.samples) { activity in
                    ActivityRow(activity: activity)
                    Divider().overlay(Color.white.opacity(0.1))
                }
            }
        }
        .overlay {
            if Activity.samples.isEmpty {
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
                ForEach(Conversation.samples) { conversation in
                    ConversationRow(conversation: conversation)
                    Divider().overlay(Color.white.opacity(0.1))
                }
            }
        }
        .overlay {
            if Conversation.samples.isEmpty {
                ContentUnavailableView {
                    Label("No Messages", systemImage: "message.slash")
                } description: {
                    Text("Direct messages from other creators will appear here.")
                }
            }
        }
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(activity.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.message(userName: activity.userName, workTitle: activity.workTitle))
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(activity.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.recipientName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(conversation.recipientName)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(conversation.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
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
