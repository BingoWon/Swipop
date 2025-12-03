//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style grid discover page
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    @Binding var isViewingWork: Bool
    
    @State private var showSearch = false
    @State private var selectedWork: Work?
    
    private let feed = FeedViewModel.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if feed.isLoading && feed.works.isEmpty {
                    loadingState
                } else if feed.isEmpty {
                    emptyState
                } else {
                    gridContent
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
    
    // MARK: - Grid Content
    
    private var gridContent: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(feed.works) { work in
                WorkGridCell(work: work)
                    .onTapGesture {
                        feed.setCurrentWork(work)
                        selectedWork = work
                    }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
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

// MARK: - Grid Cell (Xiaohongshu style)

private struct WorkGridCell: View {
    let work: Work
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image or placeholder
            coverImage
            
            // Work info
            VStack(alignment: .leading, spacing: 4) {
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
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
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
            .frame(height: 180)
            .clipped()
        } else {
            placeholderImage
                .frame(height: 180)
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
