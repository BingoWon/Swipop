//
//  FeedViewModel.swift
//  Swipop
//
//  Feed management with interaction states preloaded in single query
//

import Auth
import Foundation

@MainActor
@Observable
final class FeedViewModel {
    static let shared = FeedViewModel()

    private(set) var projects: [Project] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var error: String?

    private var hasMorePages = true
    private var needsRefresh = false
    private var hasInitialLoad = false
    private var currentTask: Task<Void, Never>?
    private let pageSize = 20

    var currentProject: Project? {
        guard currentIndex >= 0, currentIndex < projects.count else { return nil }
        return projects[currentIndex]
    }

    var isEmpty: Bool {
        !isLoading && projects.isEmpty
    }

    private init() {
        // Don't auto-load here - let view trigger it
    }

    // MARK: - Navigation

    func setCurrentProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            currentIndex = index
        }
    }

    func goToNext() {
        guard currentIndex < projects.count - 1 else { return }
        currentIndex += 1

        // Load more when approaching end
        if currentIndex >= projects.count - 3 {
            loadMore()
        }
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    // MARK: - Loading

    /// Initial load - called once when view appears
    func loadInitial() {
        guard !hasInitialLoad else { return }
        hasInitialLoad = true
        performLoad()
    }

    /// Manual refresh - user pulled to refresh
    /// Returns when loading completes (for .refreshable)
    func refresh() async {
        // Cancel any existing task
        currentTask?.cancel()

        // Wait for the load to complete
        await doLoadFeed()
    }

    /// Mark feed as needing refresh (called after login)
    func markNeedsRefresh() {
        needsRefresh = true
    }

    /// Check and refresh if needed (called when view appears)
    func refreshIfNeeded() {
        if needsRefresh {
            needsRefresh = false
            performLoad()
        }
    }

    /// Perform the actual load, managing task lifecycle
    private func performLoad() {
        // Cancel any existing task
        currentTask?.cancel()

        // Create new detached task that won't be cancelled by SwiftUI
        currentTask = Task.detached { [weak self] in
            await self?.doLoadFeed()
        }
    }

    private func doLoadFeed() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let userId = AuthService.shared.currentUser?.id
            let fetchedProjects = try await ProjectService.shared.fetchFeed(limit: pageSize, offset: 0, userId: userId)

            guard !Task.isCancelled else { return }

            projects = fetchedProjects
            hasMorePages = projects.count >= pageSize
            currentIndex = 0
            InteractionStore.shared.updateFromProjects(projects)
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription
            print("Failed to load feed: \(error)")
        }

        isLoading = false
    }

    func loadMore() {
        guard !isLoading, hasMorePages else { return }

        Task.detached { [weak self] in
            await self?.doLoadMore()
        }
    }

    private func doLoadMore() async {
        guard !isLoading, hasMorePages else { return }

        isLoading = true

        do {
            let userId = AuthService.shared.currentUser?.id
            let currentCount = projects.count
            let newProjects = try await ProjectService.shared.fetchFeed(limit: pageSize, offset: currentCount, userId: userId)

            guard !Task.isCancelled else { return }

            if newProjects.isEmpty {
                hasMorePages = false
            } else {
                projects.append(contentsOf: newProjects)
                InteractionStore.shared.updateFromProjects(newProjects)
            }
        } catch {
            print("Failed to load more: \(error)")
        }

        isLoading = false
    }
}
