//
//  ProfileView.swift
//  Swipop
//

import Auth
import SwiftUI

struct ProfileView: View {
    @Binding var showLogin: Bool
    let editProject: (Project) -> Void
    private let auth = AuthService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if auth.isAuthenticated {
                    ProfileContentView(showLogin: $showLogin, editProject: editProject)
                } else {
                    signInPrompt
                }
            }
        }
    }

    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Sign in to see your profile")
                .font(.title3)
                .foregroundStyle(.primary)

            Button {
                showLogin = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brand)
                    .cornerRadius(25)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Profile Content View (Current User)

struct ProfileContentView: View {
    @Binding var showLogin: Bool
    let editProject: (Project) -> Void

    private var userProfile: CurrentUserProfile { CurrentUserProfile.shared }
    @State private var selectedTab = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showSettings = false
    @State private var showEditProfile = false

    private let tabCount = 3

    private func itemsForTab(_ tab: Int) -> [Project] {
        switch tab {
        case 1: return userProfile.likedProjects
        case 2: return userProfile.collectedProjects
        default: return userProfile.projects
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 8) / 3, 1)
            let screenWidth = geometry.size.width

            ScrollView {
                VStack(spacing: 8) {
                    ProfileHeaderView(
                        profile: userProfile.profile,
                        showEditButton: true,
                        onEditTapped: { showEditProfile = true }
                    )

                    ProfileStatsRow(
                        projectCount: userProfile.projectCount,
                        likeCount: userProfile.likeCount,
                        followerCount: userProfile.followerCount,
                        followingCount: userProfile.followingCount
                    )

                    contentTabs
                        .padding(.top, 8)

                    // Swipeable grid container
                    swipeableGrids(columnWidth: columnWidth, screenWidth: screenWidth)
                }
            }
            .refreshable { await userProfile.refresh() }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await userProfile.refresh() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showEditProfile) { EditProfileView(profile: userProfile.profile) }
    }

    // MARK: - Swipeable Grids (Lazy: renders current ±1 tabs only)

    private func swipeableGrids(columnWidth: CGFloat, screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< tabCount, id: \.self) { tab in
                // Only render current tab and adjacent tabs for performance
                if abs(tab - selectedTab) <= 1 {
                    gridContent(tab: tab, columnWidth: columnWidth)
                        .frame(width: screenWidth)
                } else {
                    Color.clear.frame(width: screenWidth)
                }
            }
        }
        .offset(x: -CGFloat(selectedTab) * screenWidth + dragOffset)
        .frame(width: screenWidth, alignment: .leading)
        .clipped()
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Only respond to horizontal swipes (ignore vertical scrolling)
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    if horizontal > vertical {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)

                    // Only switch tabs for horizontal swipes
                    guard horizontal > vertical else {
                        withAnimation(.tabSwitch) { dragOffset = 0 }
                        return
                    }

                    let threshold = screenWidth * 0.25
                    var newTab = selectedTab

                    if value.translation.width < -threshold, selectedTab < tabCount - 1 {
                        newTab = selectedTab + 1
                    } else if value.translation.width > threshold, selectedTab > 0 {
                        newTab = selectedTab - 1
                    }

                    withAnimation(.tabSwitch) {
                        selectedTab = newTab
                        dragOffset = 0
                    }
                }
        )
        .animation(.tabSwitch, value: selectedTab)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Content Tabs

    private var contentTabs: some View {
        HStack(spacing: 0) {
            ProfileTabButton(icon: "square.grid.2x2", isSelected: selectedTab == 0) {
                withAnimation(.tabSwitch) { selectedTab = 0 }
            }
            ProfileTabButton(icon: "heart", isSelected: selectedTab == 1) {
                withAnimation(.tabSwitch) { selectedTab = 1 }
            }
            ProfileTabButton(icon: "bookmark", isSelected: selectedTab == 2) {
                withAnimation(.tabSwitch) { selectedTab = 2 }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Grid Content

    @ViewBuilder
    private func gridContent(tab: Int, columnWidth: CGFloat) -> some View {
        let items = itemsForTab(tab)
        let showDraft = tab == 0

        if items.isEmpty {
            emptyState(for: tab)
        } else {
            MasonryGrid(projects: items, columnWidth: columnWidth, columns: 3, spacing: 2) { project in
                ProfileProjectCell(project: project, columnWidth: columnWidth, showDraftBadge: showDraft && !project.isPublished)
                    .onTapGesture { editProject(project) }
            }
            .padding(.top, 2)
        }
    }

    private func emptyState(for tab: Int) -> some View {
        let icon: String
        let message: String

        switch tab {
        case 1:
            icon = "heart"
            message = "No liked projects yet"
        case 2:
            icon = "bookmark"
            message = "No saved projects yet"
        default:
            icon = "square.grid.2x2"
            message = "No projects created yet"
        }

        return VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Profile Project Cell (Cover only, minimal)

struct ProfileProjectCell: View {
    let project: Project
    let columnWidth: CGFloat
    var showDraftBadge = false

    private var imageHeight: CGFloat {
        let ratio = max(project.thumbnailAspectRatio ?? 0.75, 0.1)
        return max(columnWidth / ratio, 1)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            coverImage
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if showDraftBadge {
                Text("Draft")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(3)
                    .padding(3)
            }
        }
    }

    private var coverImage: some View {
        CachedThumbnail(project: project, transform: .small, size: CGSize(width: columnWidth, height: imageHeight))
    }
}

#Preview {
    ProfileView(showLogin: .constant(false), editProject: { _ in })
}
