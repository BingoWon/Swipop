//
//  FeedViewModel.swift
//  Swipop
//

import Foundation

@MainActor
@Observable
final class FeedViewModel {
    
    static let shared = FeedViewModel()
    
    private(set) var works: [Work] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var error: String?
    
    private var hasMorePages = true
    private let pageSize = 10
    
    var currentWork: Work? {
        guard currentIndex >= 0 && currentIndex < works.count else { return nil }
        return works[currentIndex]
    }
    
    var isEmpty: Bool {
        !isLoading && works.isEmpty
    }
    
    private init() {
        Task { await loadFeed() }
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
            Task { await loadMore() }
        }
    }
    
    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    // MARK: - Loading
    
    func loadFeed() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            works = try await WorkService.shared.fetchFeed(limit: pageSize, offset: 0)
            hasMorePages = works.count >= pageSize
            currentIndex = 0
        } catch {
            self.error = error.localizedDescription
            print("Failed to load feed: \(error)")
        }
    }
    
    func refresh() async {
        // Reset state before refresh
        hasMorePages = true
        error = nil
        
        // Force reload even if already loading (user explicitly requested)
        isLoading = false
        await loadFeed()
    }
    
    private func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        
        isLoading = true
        
        do {
            let newWorks = try await WorkService.shared.fetchFeed(limit: pageSize, offset: works.count)
            if newWorks.isEmpty {
                hasMorePages = false
            } else {
                works.append(contentsOf: newWorks)
            }
        } catch {
            // Silently fail for pagination
        }
        
        isLoading = false
    }
}
