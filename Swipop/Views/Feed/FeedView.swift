//
//  FeedView.swift
//  Swipop
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    
    @State private var interaction: InteractionViewModel?
    @State private var showComments = false
    @State private var showShare = false
    @State private var showSearch = false
    
    private let feed = FeedViewModel.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                
                if let work = feed.currentWork {
                    WorkCardView(work: work)
                        .id(feed.currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .top)
                        ))
                }
            }
            .ignoresSafeArea()
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onChange(of: feed.currentWork?.id) { _, _ in loadInteraction() }
        .task { loadInteraction() }
        .sheet(isPresented: $showComments) {
            if let work = feed.currentWork {
                CommentSheet(work: work, showLogin: $showLogin)
            }
        }
        .sheet(isPresented: $showShare) {
            if let work = feed.currentWork {
                ShareSheet(work: work)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if let work = feed.currentWork {
                // Like
                Button(action: handleLike) {
                    Label(
                        "\(interaction?.likeCount ?? work.likeCount)",
                        systemImage: interaction?.isLiked == true ? "heart.fill" : "heart"
                    )
                }
                .tint(interaction?.isLiked == true ? .red : .white)
                
                // Comment
                Button { showComments = true } label: {
                    Label("\(work.commentCount)", systemImage: "bubble.right")
                }
                
                // Collect
                Button(action: handleCollect) {
                    Label(
                        "\(interaction?.collectCount ?? work.collectCount)",
                        systemImage: interaction?.isCollected == true ? "bookmark.fill" : "bookmark"
                    )
                }
                .tint(interaction?.isCollected == true ? .yellow : .white)
                
                // Share
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadInteraction() {
        guard let work = feed.currentWork else { return }
        interaction = InteractionViewModel(work: work)
        Task { await interaction?.loadState() }
    }
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction?.toggleLike() }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction?.toggleCollect() }
    }
}

#Preview {
    FeedView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
