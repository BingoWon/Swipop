//
//  ProfileView.swift
//  Swipop
//

import SwiftUI
import Auth

struct ProfileView: View {
    
    @Binding var showLogin: Bool
    let editWork: (Work) -> Void
    private let auth = AuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if auth.isAuthenticated {
                    ProfileContentView(showLogin: $showLogin, editWork: editWork)
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
    let editWork: (Work) -> Void
    
    private var userProfile: CurrentUserProfile { CurrentUserProfile.shared }
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    
    private var currentItems: [Work] {
        switch selectedTab {
        case 1: return userProfile.likedWorks
        case 2: return userProfile.collectedWorks
        default: return userProfile.works
        }
    }
    
    private var showDraftBadge: Bool { selectedTab == 0 }
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 8) / 3, 1)
            
            ScrollView {
                VStack(spacing: 8) {
                    ProfileHeaderView(
                        profile: userProfile.profile,
                        showEditButton: true,
                        onEditTapped: { showEditProfile = true }
                    )
                    
                    ProfileStatsRow(
                        workCount: userProfile.workCount,
                        likeCount: userProfile.likeCount,
                        followerCount: userProfile.followerCount,
                        followingCount: userProfile.followingCount
                    )
                    
                    contentTabs
                        .padding(.top, 8)
                    
                    // Grid with slide transition
                    gridContent(columnWidth: columnWidth)
                        .id(selectedTab)
                        .transition(.asymmetric(
                            insertion: .move(edge: selectedTab > previousTab ? .trailing : .leading),
                            removal: .move(edge: selectedTab > previousTab ? .leading : .trailing)
                        ))
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
                switchTab(to: 0)
            }
            ProfileTabButton(icon: "heart", isSelected: selectedTab == 1) {
                switchTab(to: 1)
            }
            ProfileTabButton(icon: "bookmark", isSelected: selectedTab == 2) {
                switchTab(to: 2)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func switchTab(to tab: Int) {
        guard tab != selectedTab else { return }
        previousTab = selectedTab
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = tab
        }
    }
    
    // MARK: - Grid Content
    
    @ViewBuilder
    private func gridContent(columnWidth: CGFloat) -> some View {
        if currentItems.isEmpty {
            emptyState
        } else {
            MasonryGrid(works: currentItems, columnWidth: columnWidth, columns: 3, spacing: 2) { work in
                ProfileWorkCell(work: work, columnWidth: columnWidth, showDraftBadge: showDraftBadge && !work.isPublished)
                    .onTapGesture { editWork(work) }
            }
            .padding(.top, 2)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            
            Text(emptyStateMessage)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var emptyStateIcon: String {
        switch selectedTab {
        case 1: return "heart"
        case 2: return "bookmark"
        default: return "square.grid.2x2"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedTab {
        case 1: return "No liked works yet"
        case 2: return "No saved works yet"
        default: return "No works created yet"
        }
    }
}

// MARK: - Profile Work Cell (Cover only, minimal)

struct ProfileWorkCell: View {
    let work: Work
    let columnWidth: CGFloat
    var showDraftBadge = false
    
    private var imageHeight: CGFloat {
        let ratio = max(work.thumbnailAspectRatio ?? 0.75, 0.1)
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
        CachedThumbnail(work: work, transform: .small, size: CGSize(width: columnWidth, height: imageHeight))
    }
}

#Preview {
    ProfileView(showLogin: .constant(false), editWork: { _ in })
}
