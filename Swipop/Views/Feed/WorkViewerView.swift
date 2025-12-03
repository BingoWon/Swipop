//
//  WorkViewerView.swift
//  Swipop
//
//  Fullscreen work viewer (TikTok style swipe)
//

import SwiftUI

struct WorkViewerView: View {
    
    let initialWork: Work
    @Binding var showLogin: Bool
    let onDismiss: () -> Void
    
    @State private var interaction: InteractionViewModel?
    @State private var showComments = false
    @State private var showShare = false
    @State private var showDetail = false
    
    @Environment(\.dismiss) private var dismiss
    
    private let feed = FeedViewModel.shared
    
    var body: some View {
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
            
            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                Spacer()
            }
            
            // Right side action buttons
            actionButtons
            
            // Bottom info bar
            bottomInfoBar
        }
        .ignoresSafeArea()
        .onAppear {
            feed.setCurrentWork(initialWork)
            loadInteraction()
        }
        .onChange(of: feed.currentWork?.id) { _, _ in loadInteraction() }
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
        .sheet(isPresented: $showDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
    }
    
    // MARK: - Action Buttons (TikTok style right side)
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if let work = feed.currentWork {
                // Like
                ActionButton(
                    icon: interaction?.isLiked == true ? "heart.fill" : "heart",
                    count: interaction?.likeCount ?? work.likeCount,
                    color: interaction?.isLiked == true ? .red : .white,
                    action: handleLike
                )
                
                // Comment
                ActionButton(
                    icon: "bubble.right",
                    count: work.commentCount,
                    color: .white,
                    action: { showComments = true }
                )
                
                // Collect
                ActionButton(
                    icon: interaction?.isCollected == true ? "bookmark.fill" : "bookmark",
                    count: interaction?.collectCount ?? work.collectCount,
                    color: interaction?.isCollected == true ? .yellow : .white,
                    action: handleCollect
                )
                
                // Share
                ActionButton(
                    icon: "arrowshape.turn.up.right",
                    count: work.shareCount,
                    color: .white,
                    action: { showShare = true }
                )
            }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Bottom Info Bar
    
    private var bottomInfoBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                // Work info
                Button { showDetail = true } label: {
                    workInfoContent
                }
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }
    
    private var workInfoContent: some View {
        HStack(spacing: 10) {
            // Creator avatar
            Circle()
                .fill(Color.brand)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(creatorInitial)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feed.currentWork?.title ?? "Swipop")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text("@\(feed.currentWork?.creator?.username ?? "swipop")")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToPrevious()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
            .opacity(feed.currentIndex == 0 ? 0.3 : 1)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    private var creatorInitial: String {
        String((feed.currentWork?.creator?.displayName ?? feed.currentWork?.creator?.username ?? "S").prefix(1)).uppercased()
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

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
                
                Text(count.formatted)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    WorkViewerView(
        initialWork: .sample,
        showLogin: .constant(false),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

