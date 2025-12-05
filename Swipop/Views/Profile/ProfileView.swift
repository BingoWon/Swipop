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
    @State private var dragOffset: CGFloat = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    
    private let tabCount = 3
    
    private func itemsForTab(_ tab: Int) -> [Work] {
        switch tab {
        case 1: return userProfile.likedWorks
        case 2: return userProfile.collectedWorks
        default: return userProfile.works
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
                        workCount: userProfile.workCount,
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
    
    // MARK: - Swipeable Grids
    
    private func swipeableGrids(columnWidth: CGFloat, screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<tabCount, id: \.self) { tab in
                gridContent(tab: tab, columnWidth: columnWidth)
                    .frame(width: screenWidth)
            }
        }
        .offset(x: -CGFloat(selectedTab) * screenWidth + dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold = screenWidth * 0.25
                    var newTab = selectedTab
                    
                    if value.translation.width < -threshold && selectedTab < tabCount - 1 {
                        newTab = selectedTab + 1
                    } else if value.translation.width > threshold && selectedTab > 0 {
                        newTab = selectedTab - 1
                    }
                    
                    withAnimation(.easeOut(duration: 0.25)) {
                        selectedTab = newTab
                        dragOffset = 0
                    }
                }
        )
        .animation(.easeOut(duration: 0.25), value: selectedTab)
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
                withAnimation(.easeOut(duration: 0.25)) { selectedTab = 0 }
            }
            ProfileTabButton(icon: "heart", isSelected: selectedTab == 1) {
                withAnimation(.easeOut(duration: 0.25)) { selectedTab = 1 }
            }
            ProfileTabButton(icon: "bookmark", isSelected: selectedTab == 2) {
                withAnimation(.easeOut(duration: 0.25)) { selectedTab = 2 }
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
            MasonryGrid(works: items, columnWidth: columnWidth, columns: 3, spacing: 2) { work in
                ProfileWorkCell(work: work, columnWidth: columnWidth, showDraftBadge: showDraft && !work.isPublished)
                    .onTapGesture { editWork(work) }
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
            message = "No liked works yet"
        case 2:
            icon = "bookmark"
            message = "No saved works yet"
        default:
            icon = "square.grid.2x2"
            message = "No works created yet"
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
