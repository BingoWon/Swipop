//
//  WorkViewerPage.swift
//  Swipop
//
//  Independent full-screen work viewer with native navigation
//

import SwiftUI

struct WorkViewerPage: View {
    
    let initialWork: Work
    @Binding var showLogin: Bool
    
    @State private var interaction: InteractionViewModel
    @State private var showComments = false
    @State private var showShare = false
    @State private var showDetail = false
    
    private let feed = FeedViewModel.shared
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.initialWork = work
        self._showLogin = showLogin
        self._interaction = State(initialValue: InteractionViewModel(work: work))
    }
    
    private var currentWork: Work {
        feed.currentWork ?? initialWork
    }
    
    private var creator: Profile? {
        currentWork.creator
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Work content
            WorkWebView(work: currentWork)
                .id(feed.currentIndex)
                .ignoresSafeArea()
            
            // Floating bottom accessory (Liquid Glass style)
            floatingAccessory
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar { toolbarContent }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showComments) {
            CommentSheet(work: currentWork, showLogin: $showLogin)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(work: currentWork)
        }
        .sheet(isPresented: $showDetail) {
            WorkDetailSheet(work: currentWork, showLogin: $showLogin)
        }
        .onChange(of: feed.currentWork?.id) { _, _ in
            loadInteraction()
        }
        .onAppear {
            feed.setCurrentWork(initialWork)
            loadInteraction()
        }
    }
    
    // MARK: - Floating Accessory
    
    private var floatingAccessory: some View {
        HStack(spacing: 0) {
            Button { showDetail = true } label: {
                workInfoLabel
            }
            
            Spacer(minLength: 0)
            
            navigationButtons
        }
        .foregroundStyle(.primary)
        .frame(height: 52)
        .background { glassBackground }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(creator?.initial ?? "?")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentWork.title.isEmpty ? "Untitled" : currentWork.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("@\(creator?.handle ?? "unknown")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 14)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToPrevious()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .opacity(feed.currentIndex == 0 ? 0.3 : 1)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.trailing, 4)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Action buttons
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Like
            Button(action: handleLike) {
                Label(
                    "\(interaction.likeCount)",
                    systemImage: interaction.isLiked ? "heart.fill" : "heart"
                )
            }
            .tint(interaction.isLiked ? .red : .primary)
            
            // Comment
            Button { showComments = true } label: {
                Label("\(currentWork.commentCount)", systemImage: "bubble.right")
            }
            
            // Collect
            Button(action: handleCollect) {
                Label(
                    "\(interaction.collectCount)",
                    systemImage: interaction.isCollected ? "bookmark.fill" : "bookmark"
                )
            }
            .tint(interaction.isCollected ? .yellow : .primary)
            
            // Share
            Button { showShare = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadInteraction() {
        interaction = InteractionViewModel(work: currentWork)
        Task { await interaction.loadState() }
    }
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction.toggleLike() }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction.toggleCollect() }
    }
}

#Preview {
    NavigationStack {
        WorkViewerPage(work: .sample, showLogin: .constant(false))
    }
}

