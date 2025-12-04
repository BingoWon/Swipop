//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style masonry grid discover page with native navigation
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    @Binding var isViewingWork: Bool
    
    @State private var showSearch = false
    @State private var selectedWork: Work?
    
    private let feed = FeedViewModel.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                gridView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedWork) { work in
                WorkViewerPage(work: work, showLogin: $showLogin)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .onChange(of: selectedWork) { _, newValue in
            isViewingWork = newValue != nil
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
                                selectedWork = work
                            }
                    }
                    .padding(.top, 4)
                }
            }
            .refreshable { await feed.refresh() }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Discover")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.primary)
            }
        }
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
                    
                    Text("@\(work.creator?.handle ?? "user")")
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
        CachedThumbnail(work: work, transform: .medium, size: CGSize(width: columnWidth, height: imageHeight))
    }
    
    private var creatorInitial: String {
        work.creator?.initial ?? "U"
    }
}

#Preview {
    FeedView(showLogin: .constant(false), isViewingWork: .constant(false))
}
