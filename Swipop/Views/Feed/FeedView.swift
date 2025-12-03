//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style masonry grid discover page
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
            GeometryReader { geometry in
                let columnWidth = (geometry.size.width - 12) / 2 // 4px spacing * 3
                
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
                                    selectedWork = work
                                }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable { await feed.refresh() }
        }
        .fullScreenCover(item: $selectedWork) { work in
            WorkViewerView(
                initialWork: work,
                showLogin: $showLogin,
                onDismiss: { selectedWork = nil }
            )
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .onChange(of: selectedWork) { _, newValue in
            isViewingWork = newValue != nil
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Discover")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - States
    
    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No works yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Be the first to create!")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

// MARK: - Grid Cell (Xiaohongshu style with dynamic height)

struct WorkGridCell: View {
    let work: Work
    let columnWidth: CGFloat
    
    /// Image height based on aspect ratio
    private var imageHeight: CGFloat {
        let aspectRatio = work.coverAspectRatio ?? 1.0
        return columnWidth / aspectRatio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            coverImage
                .frame(width: columnWidth, height: imageHeight)
                .clipped()
            
            // Work info
            VStack(alignment: .leading, spacing: 6) {
                Text(work.title.isEmpty ? "Untitled" : work.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    // Creator avatar
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
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Like count
                    HStack(spacing: 2) {
                        Image(systemName: "heart")
                            .font(.system(size: 10))
                        Text(work.likeCount.formatted)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(width: columnWidth)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var coverImage: some View {
        if let urlString = work.thumbnailUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brand.opacity(0.3), Color.brand.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                Text(displayText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }
    
    private var displayText: String {
        if !work.title.isEmpty {
            return String(work.title.prefix(2)).uppercased()
        }
        if work.htmlContent?.isEmpty == false { return "H" }
        if work.cssContent?.isEmpty == false { return "C" }
        if work.jsContent?.isEmpty == false { return "J" }
        return "?"
    }
    
    private var creatorInitial: String {
        String((work.creator?.displayName ?? work.creator?.username ?? "U").prefix(1)).uppercased()
    }
}

#Preview {
    FeedView(showLogin: .constant(false), isViewingWork: .constant(false))
        .preferredColorScheme(.dark)
}
