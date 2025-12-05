//
//  SearchSheet.swift
//  Swipop
//
//  Search works and creators
//

import SwiftUI

struct SearchSheet: View {
    
    @Binding var showLogin: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceSettings.self) private var appearance
    @State private var viewModel = SearchViewModel()
    @State private var selectedWork: Work?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.searchQuery.isEmpty {
                    trendingContent
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchQuery, prompt: "Works, creators, #tags...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationDestination(item: $selectedWork) { work in
                WorkViewerPage(work: work, showLogin: .constant(false))
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .glassSheetBackground()
        .preferredColorScheme(appearance.colorScheme)
        .task {
            await viewModel.loadTrending()
        }
    }
    
    // MARK: - Trending Content
    
    private var trendingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoadingTrending {
                    loadingState
                } else {
                    trendingSection
                    if !viewModel.suggestedCreators.isEmpty {
                        suggestedCreatorsSection
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(minHeight: 200)
    }
    
    // MARK: - Trending Tags
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Trending", systemImage: "flame.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            
            FlowLayout(spacing: 8) {
                ForEach(viewModel.trendingTags, id: \.self) { tag in
                    Button {
                        viewModel.searchTag(tag)
                    } label: {
                        Text("#\(tag)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brand.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    // MARK: - Suggested Creators
    
    private var suggestedCreatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Creators", systemImage: "person.2.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.suggestedCreators) { creator in
                        NavigationLink {
                            UserProfileView(userId: creator.id, showLogin: $showLogin)
                        } label: {
                            creatorCard(creator)
                        }
                    }
                }
            }
        }
    }
    
    private func creatorCard(_ creator: Profile) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.brand)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(creator.initial)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            Text("@\(creator.handle)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if viewModel.isSearching {
                    searchingIndicator
                } else if viewModel.works.isEmpty && viewModel.users.isEmpty {
                    emptyResults
                } else {
                    if !viewModel.users.isEmpty {
                        usersResults
                    }
                    if !viewModel.works.isEmpty {
                        worksResults
                    }
                }
            }
        }
    }
    
    private var searchingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 40)
            Spacer()
        }
    }
    
    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No results for \"\(viewModel.searchQuery)\"")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Users Results
    
    private var usersResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Creators")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            ForEach(viewModel.users) { user in
                NavigationLink {
                    UserProfileView(userId: user.id, showLogin: $showLogin)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(user.initial)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName ?? user.handle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("@\(user.handle)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Works Results
    
    private var worksResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Works")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            ForEach(viewModel.works) { work in
                Button {
                    selectedWork = work
                } label: {
                    workRow(work)
                }
            }
        }
    }
    
    private func workRow(_ work: Work) -> some View {
        HStack(spacing: 12) {
            CachedThumbnail(work: work, transform: .small, size: CGSize(width: 60, height: 60))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(work.displayTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("@\(work.creator?.handle ?? "unknown")")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        Text(work.likeCount.formatted)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    SearchSheet(showLogin: .constant(false))
}
