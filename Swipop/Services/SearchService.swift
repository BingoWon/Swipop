//
//  SearchService.swift
//  Swipop
//
//  Search works and users
//

import Foundation
import Supabase

actor SearchService {
    
    static let shared = SearchService()
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Search Works
    
    /// Search works by title, description, or tags
    func searchWorks(query: String, limit: Int = 20) async throws -> [Work] {
        guard !query.isEmpty else { return [] }
        
        let searchPattern = "%\(query.lowercased())%"
        
        let works: [Work] = try await supabase
            .from("works")
            .select("*, users(*)")
            .eq("is_published", value: true)
            .or("title.ilike.\(searchPattern),description.ilike.\(searchPattern)")
            .order("like_count", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return works
    }
    
    /// Search works by tag
    func searchWorksByTag(tag: String, limit: Int = 20) async throws -> [Work] {
        guard !tag.isEmpty else { return [] }
        
        let works: [Work] = try await supabase
            .from("works")
            .select("*, users(*)")
            .eq("is_published", value: true)
            .contains("tags", value: [tag.lowercased()])
            .order("like_count", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return works
    }
    
    // MARK: - Search Users
    
    /// Search users by handle or display name
    func searchUsers(query: String, limit: Int = 20) async throws -> [Profile] {
        guard !query.isEmpty else { return [] }
        
        let searchPattern = "%\(query.lowercased())%"
        
        let users: [Profile] = try await supabase
            .from("users")
            .select("*")
            .or("handle.ilike.\(searchPattern),display_name.ilike.\(searchPattern)")
            .limit(limit)
            .execute()
            .value
        
        return users
    }
    
    // MARK: - Trending Tags
    
    /// Get trending tags (most used in recent works)
    func fetchTrendingTags(limit: Int = 10) async throws -> [String] {
        // Fetch recent published works with tags
        let works: [Work] = try await supabase
            .from("works")
            .select("tags")
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
        
        // Count tag occurrences
        var tagCounts: [String: Int] = [:]
        for work in works {
            for tag in work.tags ?? [] {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Sort by count and return top tags
        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }
    
    // MARK: - Suggested Creators
    
    /// Get suggested creators (most followed or most works)
    func fetchSuggestedCreators(limit: Int = 10) async throws -> [Profile] {
        let users: [Profile] = try await supabase
            .from("users")
            .select("*")
            .order("follower_count", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return users
    }
}

