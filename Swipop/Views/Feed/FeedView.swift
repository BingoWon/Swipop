//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style masonry grid discover page with inline work viewer
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    @Binding var isViewingWork: Bool
    
    @State private var showSearch = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showDetail = false
    @State private var interaction: InteractionViewModel?
    
    private let feed = FeedViewModel.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if isViewingWork {
                    // Fullscreen work viewer (inline, not fullScreenCover)
                    workViewer
                } else {
                    // Grid discover view
                    gridView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
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
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .onChange(of: feed.currentWork?.id) { _, _ in
            loadInteraction()
        }
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - 12) / 2
            
            ScrollView {
                if feed.isLoading && feed.works.isEmpty {
                    loadingState
                } else if feed.isEmpty {
                    emptyState
                } else {
                    MasonryGrid(works: feed.works, columnWidth: columnWidth, spacing: 4) { work in
                        WorkGridCell(work: work, columnWidth: columnWidth)
                            .onTapGesture {
                                feed.setCurrentWork(work)
                                loadInteraction()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isViewingWork = true
                                }
                            }
                    }
                    .padding(.top, 4)
                }
            }
            .refreshable { await feed.refresh() }
        }
    }
    
    // MARK: - Work Viewer (Inline)
    
    private var workViewer: some View {
        Group {
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
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Leading: Back button when viewing work
        if isViewingWork {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isViewingWork = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Discover")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        
        // Title (only in grid mode)
        if !isViewingWork {
            ToolbarItem(placement: .principal) {
                Text("Discover")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        
        // Trailing: Actions
        ToolbarItemGroup(placement: .topBarTrailing) {
            if isViewingWork, let work = feed.currentWork {
                // Like
                Button(action: handleLike) {
                    Label(
                        "\(interaction?.likeCount ?? work.likeCount)",
                        systemImage: interaction?.isLiked == true ? "heart.fill" : "heart"
                    )
                }
                .tint(interaction?.isLiked == true ? .red : .primary)
                
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
                .tint(interaction?.isCollected == true ? .yellow : .primary)
                
                // Share
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        
        if !isViewingWork {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isViewingWork ? .white : .primary)
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
    
    // MARK: - States
    
    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No works yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text("Be the first to create!")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

// MARK: - Grid Cell (Xiaohongshu style with dynamic height)

struct WorkGridCell: View {
    let work: Work
    let columnWidth: CGFloat
    
    private var imageHeight: CGFloat {
        columnWidth / (work.thumbnailAspectRatio ?? 0.75)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage
                .frame(width: columnWidth, height: imageHeight)
                .clipped()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(work.title.isEmpty ? "Untitled" : work.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Text(creatorInitial)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    
                    Text(work.creator?.username ?? "user")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "heart")
                            .font(.system(size: 10))
                        Text(work.likeCount.formatted)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(width: columnWidth)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var coverImage: some View {
        CachedThumbnail(work: work, size: .medium)
    }
    
    private var creatorInitial: String {
        String((work.creator?.displayName ?? work.creator?.username ?? "U").prefix(1)).uppercased()
    }
}

#Preview {
    FeedView(showLogin: .constant(false), isViewingWork: .constant(false))
}
