//
//  WorkViewerPage.swift
//  Swipop
//
//  Full-screen work viewer with native navigation
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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WorkWebView(work: currentWork)
                .id(feed.currentIndex)
                .ignoresSafeArea()
            
            // iOS 18: floating accessory | iOS 26: uses native tabViewBottomAccessory
            if #unavailable(iOS 26.0) {
                FloatingWorkAccessory(showDetail: $showDetail)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar { toolbarContent }
        .toolbarBackground(.hidden, for: .navigationBar)
        .minimalBackButton()
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
            reloadInteraction()
        }
        .onAppear {
            feed.setCurrentWork(initialWork)
            reloadInteraction()
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: handleLike) {
                Label("\(interaction.likeCount)", systemImage: interaction.isLiked ? "heart.fill" : "heart")
            }
            .tint(interaction.isLiked ? .red : .primary)
            
            Button { showComments = true } label: {
                Label("\(currentWork.commentCount)", systemImage: "bubble.right")
            }
            
            Button(action: handleCollect) {
                Label("\(interaction.collectCount)", systemImage: interaction.isCollected ? "bookmark.fill" : "bookmark")
            }
            .tint(interaction.isCollected ? .yellow : .primary)
            
            Button { showShare = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    // MARK: - Actions
    
    private func reloadInteraction() {
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
