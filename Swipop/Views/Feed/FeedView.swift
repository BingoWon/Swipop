//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style masonry grid discover page with native navigation
//

import SwiftUI
import Auth

struct FeedView: View {
    
    @Binding var showLogin: Bool
    
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
            SearchSheet(showLogin: $showLogin)
        }
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 12) / 2, 1)
            
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
    
    @State private var viewModel: InteractionViewModel
    
    init(work: Work, columnWidth: CGFloat) {
        self.work = work
        self.columnWidth = columnWidth
        _viewModel = State(initialValue: InteractionViewModel(work: work))
    }
    
    private var imageHeight: CGFloat {
        let ratio = max(work.thumbnailAspectRatio ?? 0.75, 0.1)
        return max(columnWidth / ratio, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedThumbnail(work: work, transform: .medium, size: CGSize(width: columnWidth, height: imageHeight))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(work.displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Text(work.creator?.initial ?? "U")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    
                    Text(work.creator?.displayName ?? work.creator?.handle ?? "User")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    LikeButton(viewModel: viewModel, size: .compact)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 5)
        }
        .frame(width: columnWidth)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reusable Like Button

struct LikeButton: View {
    let viewModel: InteractionViewModel
    var size: Size = .regular
    
    enum Size {
        case compact, regular
        
        var iconSize: CGFloat {
            switch self {
            case .compact: return 13
            case .regular: return 16
            }
        }
        
        var textSize: CGFloat {
            switch self {
            case .compact: return 13
            case .regular: return 14
            }
        }
    }
    
    var body: some View {
        Button {
            Task { await viewModel.toggleLike() }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: size.iconSize))
                Text(viewModel.likeCount.formatted)
                    .font(.system(size: size.textSize))
            }
            .foregroundStyle(viewModel.isLiked ? .red : .secondary)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 28)
    }
}

#Preview {
    FeedView(showLogin: .constant(false))
}
