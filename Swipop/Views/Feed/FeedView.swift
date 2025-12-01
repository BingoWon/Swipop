//
//  FeedView.swift
//  Swipop
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    
    @State private var interaction: InteractionViewModel?
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var showSearch = false
    @State private var triggerLikeAnimation = false
    
    private let feed = FeedViewModel.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                
                if let work = feed.currentWork {
                    WorkCardView(work: work, triggerLikeAnimation: $triggerLikeAnimation)
                        .id(feed.currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .top)
                        ))
                        .onTapGesture(count: 2) {
                            doubleTapLike()
                        }
                }
                
                // Like animation overlay
                if triggerLikeAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let work = feed.currentWork {
                        // Like
                        Button {
                            handleLike()
                        } label: {
                            Label(
                                "\(interaction?.likeCount ?? work.likeCount)",
                                systemImage: interaction?.isLiked == true ? "heart.fill" : "heart"
                            )
                        }
                        .tint(interaction?.isLiked == true ? .red : .white)
                        
                        // Comment
                        Button {
                            showComments = true
                        } label: {
                            Label("\(work.commentCount)", systemImage: "bubble.right")
                        }
                        
                        // Collect
                        Button {
                            handleCollect()
                        } label: {
                            Label(
                                "\(interaction?.collectCount ?? work.collectCount)",
                                systemImage: interaction?.isCollected == true ? "bookmark.fill" : "bookmark"
                            )
                        }
                        .tint(interaction?.isCollected == true ? .yellow : .white)
                        
                        // Share
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if value.translation.height < -50 {
                            feed.goToNext()
                        } else if value.translation.height > 50 {
                            feed.goToPrevious()
                        }
                    }
                }
        )
        .onChange(of: feed.currentWork?.id) { _, _ in
            loadInteraction()
        }
        .task {
            loadInteraction()
        }
        .sheet(isPresented: $showComments) {
            if let work = feed.currentWork {
                CommentSheet(work: work, showLogin: $showLogin)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let work = feed.currentWork {
                ShareSheet(work: work)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
    }
    
    // MARK: - Helpers
    
    private func loadInteraction() {
        guard let work = feed.currentWork else { return }
        interaction = InteractionViewModel(work: work)
        Task {
            await interaction?.loadState()
        }
    }
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        withAnimation(.spring(response: 0.3)) {
            Task { await interaction?.toggleLike() }
        }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        withAnimation(.spring(response: 0.3)) {
            Task { await interaction?.toggleCollect() }
        }
    }
    
    private func doubleTapLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        // Only like, don't unlike on double-tap
        if interaction?.isLiked != true {
            Task { await interaction?.toggleLike() }
        }
        
        // Show animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            triggerLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                triggerLikeAnimation = false
            }
        }
    }
}

#Preview {
    FeedView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
