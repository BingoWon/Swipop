//
//  WorkDetailSheet.swift
//  Swipop
//
//  Work details with creator info, stats, and source code
//

import SwiftUI
import Auth

struct WorkDetailSheet: View {
    
    let work: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var interaction: InteractionViewModel
    @State private var followState = FollowState()
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var showCreatorProfile = false
    @State private var selectedLanguage: CodeLanguage = .html
    @State private var codeCopied = false
    
    private var creator: Profile? { work.creator }
    private var isSelf: Bool { AuthService.shared.currentUser?.id == creator?.id }
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.work = work
        self._showLogin = showLogin
        self._interaction = State(initialValue: InteractionViewModel(work: work))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    creatorSection
                    Divider().background(Color.border)
                    workSection
                    Divider().background(Color.border)
                    actionsSection
                    Divider().background(Color.border)
                    sourceCodeSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(work.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .navigationDestination(isPresented: $showCreatorProfile) {
                if let creatorId = creator?.id {
                    UserProfileView(userId: creatorId, showLogin: $showLogin)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .glassSheetBackground()
        .task {
            await interaction.loadState()
            await loadFollowState()
        }
        .sheet(isPresented: $showComments) {
            CommentSheet(work: work, showLogin: $showLogin)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(work: work)
        }
    }
    
    // MARK: - Creator Section
    
    private var creatorSection: some View {
        HStack(spacing: 12) {
            Button { showCreatorProfile = true } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(creator?.initial ?? "?")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(creator?.handle ?? "unknown")")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if let bio = creator?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Only show Follow button if not viewing own work
            if !isSelf {
                Button {
                    requireLogin {
                        Task { await toggleFollow() }
                    }
                } label: {
                    Text(followState.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(followState.isFollowing ? .primary : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(followState.isFollowing ? Color.secondaryBackground : Color.brand)
                        .cornerRadius(20)
                }
                .disabled(followState.isLoading)
            }
        }
    }
    
    private var workSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(work.displayTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            if let description = work.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            
            Text(work.createdAt.timeAgo)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 0) {
            StatActionTile(icon: "eye", count: work.viewCount, tint: .primary)
            
            StatActionTile(
                icon: interaction.isLiked ? "heart.fill" : "heart",
                count: interaction.likeCount,
                tint: interaction.isLiked ? .red : .primary
            ) {
                requireLogin { Task { await interaction.toggleLike() } }
            }
            
            StatActionTile(icon: "bubble.right", count: work.commentCount, tint: .primary) {
                showComments = true
            }
            
            StatActionTile(
                icon: interaction.isCollected ? "bookmark.fill" : "bookmark",
                count: interaction.collectCount,
                tint: interaction.isCollected ? .yellow : .primary
            ) {
                requireLogin { Task { await interaction.toggleCollect() } }
            }
            
            StatActionTile(icon: "square.and.arrow.up", count: work.shareCount, tint: .primary) {
                showShareSheet = true
            }
        }
    }
    
    private var sourceCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with language picker and copy button
            HStack(spacing: 12) {
                // Language picker (compact)
                Picker("", selection: $selectedLanguage) {
                    ForEach(CodeLanguage.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                
                Spacer()
                
                // Copy button
                Button {
                    copyCode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                        Text(codeCopied ? "Copied" : "Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(codeCopied ? .green : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondaryBackground, in: Capsule())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: codeCopied)
            }
            
            // Code view (2/3 screen height)
            GeometryReader { geo in
                RunestoneCodeView(language: selectedLanguage, code: currentCode)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
            }
            .frame(height: UIScreen.main.bounds.height * 2 / 3)
        }
    }
    
    private func copyCode() {
        UIPasteboard.general.string = currentCode
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Show "Copied" state
        codeCopied = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            codeCopied = false
        }
    }
    
    private var currentCode: String {
        switch selectedLanguage {
        case .html: work.htmlContent ?? "<!-- No HTML content -->"
        case .css: work.cssContent ?? "/* No CSS content */"
        case .javascript: work.jsContent ?? "// No JavaScript content"
        }
    }
    
    // MARK: - Actions
    
    private func loadFollowState() async {
        guard let creatorId = creator?.id,
              let currentUserId = AuthService.shared.currentUser?.id,
              creatorId != currentUserId else { return }
        
        followState.isLoading = true
        defer { followState.isLoading = false }
        
        do {
            followState.isFollowing = try await UserService.shared.isFollowing(
                followerId: currentUserId,
                followingId: creatorId
            )
        } catch {
            print("Failed to load follow state: \(error)")
        }
    }
    
    private func toggleFollow() async {
        guard let creatorId = creator?.id,
              let currentUserId = AuthService.shared.currentUser?.id,
              creatorId != currentUserId else { return }
        
        let wasFollowing = followState.isFollowing
        followState.isFollowing.toggle()
        
        do {
            if followState.isFollowing {
                try await UserService.shared.follow(followerId: currentUserId, followingId: creatorId)
            } else {
                try await UserService.shared.unfollow(followerId: currentUserId, followingId: creatorId)
            }
        } catch {
            followState.isFollowing = wasFollowing
            print("Failed to toggle follow: \(error)")
        }
    }
    
    private func requireLogin(action: @escaping () -> Void) {
        if AuthService.shared.isAuthenticated {
            action()
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLogin = true
            }
        }
    }
}

// MARK: - Follow State

private struct FollowState {
    var isFollowing = false
    var isLoading = false
}

// MARK: - Stat Action Tile

private struct StatActionTile: View {
    let icon: String
    let count: Int
    var tint: Color = .primary
    var action: (() -> Void)?
    
    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var content: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
            Text(count.formatted)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WorkDetailSheet(work: .sample, showLogin: .constant(false))
}
