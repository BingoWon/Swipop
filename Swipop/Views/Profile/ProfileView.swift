//
//  ProfileView.swift
//  Swipop
//

import SwiftUI
import Auth

struct ProfileView: View {
    
    @Binding var showLogin: Bool
    private let auth = AuthService.shared
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if auth.isAuthenticated, let userId = auth.currentUser?.id {
                    ProfileContentView(userId: userId, showLogin: $showLogin)
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

// MARK: - Profile Content View

struct ProfileContentView: View {
    
    let userId: UUID
    @Binding var showLogin: Bool
    
    @State private var viewModel: ProfileViewModel
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var selectedWorkForEdit: Work?
    
    init(userId: UUID, showLogin: Binding<Bool>) {
        self.userId = userId
        self._showLogin = showLogin
        self._viewModel = State(initialValue: ProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                statsRow
                actionButtons
                contentTabs
                workGrid
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isCurrentUser {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(profile: viewModel.profile)
        }
        .sheet(item: $selectedWorkForEdit) { work in
            WorkEditorSheet(work: work) {
                // Refresh works after editing
                Task { await viewModel.refreshWorks() }
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 88, height: 88)
                .overlay(
                    Text(viewModel.profile?.username?.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(viewModel.profile?.displayName ?? viewModel.profile?.username ?? "User")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if let username = viewModel.profile?.username {
                Text("@\(username)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let bio = viewModel.profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 40) {
            StatColumn(value: viewModel.workCount, label: "Works")
            StatColumn(value: viewModel.followerCount, label: "Followers")
            StatColumn(value: viewModel.followingCount, label: "Following")
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.isCurrentUser {
                Button { showEditProfile = true } label: {
                    Text("Edit Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                }
            } else {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    Text(viewModel.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.isFollowing ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(viewModel.isFollowing ? Color.white.opacity(0.15) : Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Content Tabs
    
    private var contentTabs: some View {
        HStack(spacing: 0) {
            TabButton(icon: "square.grid.2x2", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            if viewModel.isCurrentUser {
                TabButton(icon: "heart", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(icon: "bookmark", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Work Grid
    
    private var workGrid: some View {
        let items = currentItems
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2)
        ], spacing: 2) {
            ForEach(items) { work in
                WorkThumbnail(work: work, showDraftBadge: viewModel.isCurrentUser && !work.isPublished)
                    .onTapGesture {
                        if viewModel.isCurrentUser {
                            selectedWorkForEdit = work
                        }
                    }
            }
        }
        .padding(.top, 2)
    }
    
    private var currentItems: [Work] {
        switch selectedTab {
        case 1: return viewModel.likedWorks
        case 2: return viewModel.collectedWorks
        default: return viewModel.works
        }
    }
}

// MARK: - Supporting Views

private struct StatColumn: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value.formatted)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

private struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct WorkThumbnail: View {
    let work: Work
    var showDraftBadge = false
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: "1a1a2e"))
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                VStack(spacing: 4) {
                    Text(displayText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                    
                    if !work.title.isEmpty {
                        Text(work.title)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if showDraftBadge {
                    Text("Draft")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(4)
                        .padding(4)
                }
            }
    }
    
    private var displayText: String {
        if !work.title.isEmpty {
            return String(work.title.prefix(2)).uppercased()
        }
        // Show icon based on content
        if work.htmlContent?.isEmpty == false { return "H" }
        if work.cssContent?.isEmpty == false { return "C" }
        if work.jsContent?.isEmpty == false { return "J" }
        return "?"
    }
}

#Preview {
    ProfileView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
