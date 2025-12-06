//
//  SearchService.swift
//  Swipop
//
//  Search projects and users
//

import Foundation
import Supabase

actor SearchService {
    static let shared = SearchService()

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Search Projects

    /// Search projects by title, description, or tags
    func searchProjects(query: String, limit: Int = 20) async throws -> [Project] {
        guard !query.isEmpty else { return [] }

        // Use wildcards for partial matching
        let pattern = "%\(query)%"

        let projects: [Project] = try await supabase
            .from("projects")
            .select("*, users(*)")
            .eq("is_published", value: true)
            .ilike("title", pattern: pattern)
            .order("like_count", ascending: false)
            .limit(limit)
            .execute()
            .value

        return projects
    }

    /// Search projects by title or description
    func searchProjectsByText(query: String, limit: Int = 20) async throws -> [Project] {
        guard !query.isEmpty else { return [] }

        let pattern = "%\(query)%"

        // Search title first, then description as fallback
        var projects: [Project] = try await supabase
            .from("projects")
            .select("*, users(*)")
            .eq("is_published", value: true)
            .ilike("title", pattern: pattern)
            .order("like_count", ascending: false)
            .limit(limit)
            .execute()
            .value

        // If no title matches, search description
        if projects.isEmpty {
            projects = try await supabase
                .from("projects")
                .select("*, users(*)")
                .eq("is_published", value: true)
                .ilike("description", pattern: pattern)
                .order("like_count", ascending: false)
                .limit(limit)
                .execute()
                .value
        }

        return projects
    }

    /// Search projects by tag
    func searchProjectsByTag(tag: String, limit: Int = 20) async throws -> [Project] {
        guard !tag.isEmpty else { return [] }

        let projects: [Project] = try await supabase
            .from("projects")
            .select("*, users(*)")
            .eq("is_published", value: true)
            .contains("tags", value: [tag.lowercased()])
            .order("like_count", ascending: false)
            .limit(limit)
            .execute()
            .value

        return projects
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

    /// Get trending tags (most used in recent projects)
    func fetchTrendingTags(limit: Int = 10) async throws -> [String] {
        // Fetch recent published projects with tags
        let projects: [Project] = try await supabase
            .from("projects")
            .select("tags")
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        // Count tag occurrences
        var tagCounts: [String: Int] = [:]
        for project in projects {
            for tag in project.tags ?? [] {
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

    /// Get suggested creators (most followed or most projects)
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
