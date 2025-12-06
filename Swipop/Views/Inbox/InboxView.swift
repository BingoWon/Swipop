//
//  InboxView.swift
//  Swipop
//
//  Activity notifications center with navigation to projects/profiles
//

import Auth
import SwiftUI

struct InboxView: View {
    @State private var viewModel = InboxViewModel()
    @State private var selectedActivity: Activity?
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.activities.isEmpty {
                    ProgressView().tint(.primary)
                } else if viewModel.activities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.hasUnread {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Mark all read") {
                            Task { await viewModel.markAllAsRead() }
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .navigationDestination(item: $selectedActivity) { activity in
                destinationView(for: activity)
            }
        }
        .task {
            await viewModel.loadActivities()
        }
        .sheet(isPresented: $showLogin) {
            LoginView(isPresented: $showLogin)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Activity", systemImage: "bell.slash")
        } description: {
            Text("When someone interacts with your projects, you'll see it here.")
        }
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedActivities, id: \.title) { group in
                    Section {
                        ForEach(group.activities) { activity in
                            ActivityRow(activity: activity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleActivityTap(activity)
                                }

                            if activity.id != group.activities.last?.id {
                                Divider().overlay(Color.border).padding(.leading, 68)
                            }
                        }
                    } header: {
                        sectionHeader(group.title)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadActivities()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }

    // MARK: - Navigation

    private func handleActivityTap(_ activity: Activity) {
        Task { await viewModel.markAsRead(activity) }
        selectedActivity = activity
    }

    @ViewBuilder
    private func destinationView(for activity: Activity) -> some View {
        switch activity.type {
        case .follow:
            // Navigate to the actor's profile (who followed you)
            UserProfileView(userId: activity.actorId, showLogin: $showLogin)
        case .like, .comment, .collect:
            // Navigate to the project
            if let project = activity.project {
                ProjectViewerPage(project: project, showLogin: $showLogin)
            } else {
                // Fallback: show actor's profile
                UserProfileView(userId: activity.actorId, showLogin: $showLogin)
            }
        }
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            // Actor avatar with type indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(activity.actor?.initial ?? "?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )

                Circle()
                    .fill(activity.type.color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: activity.type.icon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.message(
                    actorName: activity.actor?.handle ?? "Someone",
                    projectTitle: activity.project?.title
                ))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(2)

                Text(activity.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Right chevron for navigation hint
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)

            // Unread indicator
            if !activity.isRead {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(activity.isRead ? Color.clear : Color.brand.opacity(0.05))
    }
}

// MARK: - ViewModel

@Observable
final class InboxViewModel {
    private(set) var activities: [Activity] = []
    private(set) var isLoading = false

    var hasUnread: Bool { activities.contains { !$0.isRead } }
    var unreadCount: Int { activities.filter { !$0.isRead }.count }

    var groupedActivities: [ActivityGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [Activity] = []
        var yesterday: [Activity] = []
        var thisWeek: [Activity] = []
        var earlier: [Activity] = []

        for activity in activities {
            if calendar.isDateInToday(activity.createdAt) {
                today.append(activity)
            } else if calendar.isDateInYesterday(activity.createdAt) {
                yesterday.append(activity)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      activity.createdAt > weekAgo
            {
                thisWeek.append(activity)
            } else {
                earlier.append(activity)
            }
        }

        var groups: [ActivityGroup] = []
        if !today.isEmpty { groups.append(ActivityGroup(title: "Today", activities: today)) }
        if !yesterday.isEmpty { groups.append(ActivityGroup(title: "Yesterday", activities: yesterday)) }
        if !thisWeek.isEmpty { groups.append(ActivityGroup(title: "This Week", activities: thisWeek)) }
        if !earlier.isEmpty { groups.append(ActivityGroup(title: "Earlier", activities: earlier)) }

        return groups
    }

    private let service = ActivityService.shared
    private let auth = AuthService.shared

    @MainActor
    func loadActivities() async {
        guard let userId = auth.currentUser?.id else {
            activities = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            activities = try await service.fetchActivities(userId: userId)
        } catch {
            print("Failed to load activities: \(error)")
        }
    }

    @MainActor
    func markAsRead(_ activity: Activity) async {
        guard !activity.isRead else { return }

        // Optimistic update
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            var updated = activities[index]
            updated = Activity(
                id: updated.id,
                userId: updated.userId,
                actorId: updated.actorId,
                type: updated.type,
                projectId: updated.projectId,
                commentId: updated.commentId,
                isRead: true,
                createdAt: updated.createdAt,
                actor: updated.actor,
                project: updated.project
            )
            activities[index] = updated
        }

        do {
            try await service.markAsRead(activityId: activity.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    @MainActor
    func markAllAsRead() async {
        guard let userId = auth.currentUser?.id else { return }

        // Optimistic update
        activities = activities.map { activity in
            Activity(
                id: activity.id,
                userId: activity.userId,
                actorId: activity.actorId,
                type: activity.type,
                projectId: activity.projectId,
                commentId: activity.commentId,
                isRead: true,
                createdAt: activity.createdAt,
                actor: activity.actor,
                project: activity.project
            )
        }

        do {
            try await service.markAllAsRead(userId: userId)
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}

// MARK: - Activity Group

struct ActivityGroup {
    let title: String
    let activities: [Activity]
}

#Preview {
    InboxView()
}
