//
//  FeedViewModel.swift
//  Swipop
//
//  Feed management with interaction states preloaded in single query
//

import Foundation
import Auth

@MainActor
@Observable
final class FeedViewModel {
    
    static let shared = FeedViewModel()
    
    private(set) var works: [Work] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var error: String?
    
    private var hasMorePages = true
    private var needsRefresh = false
    private var hasInitialLoad = false
    private var currentTask: Task<Void, Never>?
    private let pageSize = 20
    
    var currentWork: Work? {
        guard currentIndex >= 0 && currentIndex < works.count else { return nil }
        return works[currentIndex]
    }
    
    var isEmpty: Bool {
        !isLoading && works.isEmpty
    }
    
    private init() {
        // Don't auto-load here - let view trigger it
    }
    
    // MARK: - Navigation
    
    func setCurrentWork(_ work: Work) {
        if let index = works.firstIndex(where: { $0.id == work.id }) {
            currentIndex = index
        }
    }
    
    func goToNext() {
        guard currentIndex < works.count - 1 else { return }
        currentIndex += 1
        
        // Load more when approaching end
        if currentIndex >= works.count - 3 {
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
            let fetchedWorks = try await WorkService.shared.fetchFeed(limit: pageSize, offset: 0, userId: userId)
            
            guard !Task.isCancelled else { return }
            
            works = fetchedWorks
            hasMorePages = works.count >= pageSize
            currentIndex = 0
            InteractionStore.shared.updateFromWorks(works)
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
            let currentCount = works.count
            let newWorks = try await WorkService.shared.fetchFeed(limit: pageSize, offset: currentCount, userId: userId)
            
            guard !Task.isCancelled else { return }
            
            if newWorks.isEmpty {
                hasMorePages = false
            } else {
                works.append(contentsOf: newWorks)
                InteractionStore.shared.updateFromWorks(newWorks)
            }
        } catch {
            print("Failed to load more: \(error)")
        }
        
        isLoading = false
    }
}
