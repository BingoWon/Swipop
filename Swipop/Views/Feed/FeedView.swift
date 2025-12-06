//
//  FeedView.swift
//  Swipop
//
//  Xiaohongshu-style masonry grid discover page with native navigation
//

import Auth
import SwiftUI

struct FeedView: View {
    @Binding var showLogin: Bool

    @State private var showSearch = false
    @State private var selectedProject: Project?
    @State private var isInitializing = true

    private let feed = FeedViewModel.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                gridView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedProject) { project in
                ProjectViewerPage(project: project, showLogin: $showLogin)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet(showLogin: $showLogin)
        }
        .task {
            // Wait for auth session to be restored before loading feed
            // This ensures we have userId for correct isLiked states
            await AuthService.shared.waitForSession()
            isInitializing = false
            feed.loadInitial()
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 12) / 2, 1)

            ScrollView {
                if isInitializing || (feed.isLoading && feed.projects.isEmpty) {
                    loadingState
                } else if feed.isEmpty {
                    emptyState
                } else {
                    MasonryGrid(projects: feed.projects, columnWidth: columnWidth, spacing: 4) { project in
                        ProjectGridCell(project: project, columnWidth: columnWidth)
                            .onTapGesture {
                                selectedProject = project
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

            Text("No projects yet")
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

struct ProjectGridCell: View {
    let project: Project
    let columnWidth: CGFloat

    private var imageHeight: CGFloat {
        let ratio = max(project.thumbnailAspectRatio ?? 0.75, 0.1)
        return max(columnWidth / ratio, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedThumbnail(project: project, transform: .medium, size: CGSize(width: columnWidth, height: imageHeight))

            VStack(alignment: .leading, spacing: 3) {
                Text(project.displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Text(project.creator?.initial ?? "U")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text(project.creator?.displayName ?? project.creator?.handle ?? "User")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    LikeButton(projectId: project.id, size: .compact)
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

// MARK: - Reusable Like Button (Uses InteractionStore)

struct LikeButton: View {
    let projectId: UUID
    var size: Size = .regular

    private let store = InteractionStore.shared

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
            Task { await store.toggleLike(projectId: projectId) }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: store.isLiked(projectId) ? "heart.fill" : "heart")
                    .font(.system(size: size.iconSize))
                Text(store.likeCount(projectId).formatted)
                    .font(.system(size: size.textSize))
            }
            .foregroundStyle(store.isLiked(projectId) ? .red : .secondary)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 28)
    }
}

#Preview {
    FeedView(showLogin: .constant(false))
}
