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
                Color.black.ignoresSafeArea()
                
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
                .foregroundColor(.white.opacity(0.5))
            
            Text("Sign in to see your profile")
                .font(.title3)
                .foregroundColor(.white)
            
            Button {
                showLogin = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
            }
        }
    }
}

// MARK: - Profile Content View (Current User)

struct ProfileContentView: View {
    
    @Binding var showLogin: Bool
    let editWork: (Work) -> Void
    
    private var userProfile: CurrentUserProfile { CurrentUserProfile.shared }
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - 8) / 3 // 3 columns, 2px spacing * 4
            
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderView(profile: userProfile.profile)
                    ProfileStatsRow(
                        workCount: userProfile.workCount,
                        followerCount: userProfile.followerCount,
                        followingCount: userProfile.followingCount
                    )
                    actionButtons
                    contentTabs
                    workMasonryGrid(columnWidth: columnWidth)
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            await userProfile.refresh()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(profile: userProfile.profile)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if userProfile.isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Button {
                    Task { await userProfile.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
        }
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { showEditProfile = true } label: {
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Content Tabs
    
    private var contentTabs: some View {
        HStack(spacing: 0) {
            ProfileTabButton(icon: "square.grid.2x2", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            ProfileTabButton(icon: "heart", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            ProfileTabButton(icon: "bookmark", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Work Masonry Grid
    
    private func workMasonryGrid(columnWidth: CGFloat) -> some View {
        MasonryGrid(works: currentItems, columnWidth: columnWidth, columns: 3, spacing: 2) { work in
            ProfileWorkCell(work: work, columnWidth: columnWidth, showDraftBadge: !work.isPublished)
                .onTapGesture {
                    editWork(work)
                }
        }
        .padding(.top, 2)
    }
    
    private var currentItems: [Work] {
        switch selectedTab {
        case 1: return userProfile.likedWorks
        case 2: return userProfile.collectedWorks
        default: return userProfile.works
        }
    }
}

// MARK: - Profile Work Cell (Cover only, minimal)

struct ProfileWorkCell: View {
    let work: Work
    let columnWidth: CGFloat
    var showDraftBadge = false
    
    private var imageHeight: CGFloat {
        columnWidth / (work.thumbnailAspectRatio ?? 0.75)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            coverImage
                .frame(width: columnWidth, height: imageHeight)
                .clipped()
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
    
    @ViewBuilder
    private var coverImage: some View {
        if let urlString = work.thumbnailUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color(hex: "1a1a2e")
            
            Text(displayText)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    private var displayText: String {
        if !work.title.isEmpty { return String(work.title.prefix(2)).uppercased() }
        if work.htmlContent?.isEmpty == false { return "H" }
        if work.cssContent?.isEmpty == false { return "C" }
        if work.jsContent?.isEmpty == false { return "J" }
        return "?"
    }
}

#Preview {
    ProfileView(showLogin: .constant(false), editWork: { _ in })
        .preferredColorScheme(.dark)
}
