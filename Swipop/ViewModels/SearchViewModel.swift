//
//  SearchViewModel.swift
//  Swipop
//
//  Search state management
//

import Foundation

@MainActor
@Observable
final class SearchViewModel {
    
    private(set) var works: [Work] = []
    private(set) var users: [Profile] = []
    private(set) var trendingTags: [String] = []
    private(set) var suggestedCreators: [Profile] = []
    
    private(set) var isSearching = false
    private(set) var isLoadingTrending = false
    
    var searchQuery = "" {
        didSet {
            if searchQuery != oldValue {
                searchTask?.cancel()
                if searchQuery.isEmpty {
                    works = []
                    users = []
                } else {
                    scheduleSearch()
                }
            }
        }
    }
    
    private var searchTask: Task<Void, Never>?
    private let service = SearchService.shared
    
    // MARK: - Load Initial Data
    
    func loadTrending() async {
        guard trendingTags.isEmpty else { return }
        
        isLoadingTrending = true
        defer { isLoadingTrending = false }
        
        do {
            async let tags = service.fetchTrendingTags()
            async let creators = service.fetchSuggestedCreators()
            
            let (fetchedTags, fetchedCreators) = try await (tags, creators)
            trendingTags = fetchedTags.isEmpty ? defaultTags : fetchedTags
            suggestedCreators = fetchedCreators
        } catch {
            print("Failed to load trending: \(error)")
            trendingTags = defaultTags
        }
    }
    
    // MARK: - Search
    
    private func scheduleSearch() {
        searchTask = Task {
            // Debounce 300ms
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }
    
    private func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            // Search by tag if query starts with #
            if query.hasPrefix("#") {
                let tag = String(query.dropFirst())
                works = try await service.searchWorksByTag(tag: tag)
                users = []
            } else {
                async let worksTask = service.searchWorks(query: query)
                async let usersTask = service.searchUsers(query: query)
                
                let (fetchedWorks, fetchedUsers) = try await (worksTask, usersTask)
                works = fetchedWorks
                users = fetchedUsers
            }
        } catch {
            print("Search failed: \(error)")
        }
    }
    
    func searchTag(_ tag: String) {
        searchQuery = "#\(tag)"
    }
    
    // MARK: - Default Tags
    
    private var defaultTags: [String] {
        ["animation", "3d", "particles", "gradient", "interactive", "generative"]
    }
}

