//
//  InteractionService.swift
//  Swipop
//
//  Service for likes, collections, and other interactions
//

import Foundation
import Supabase

actor InteractionService {
    // MARK: - Singleton

    static let shared = InteractionService()

    // MARK: - Private

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Likes

    func like(projectId: UUID, userId: UUID) async throws {
        do {
            try await supabase
                .from("likes")
                .insert(["project_id": projectId.uuidString, "user_id": userId.uuidString])
                .execute()
        } catch let error as PostgrestError where error.code == "23505" {
            // Duplicate key - already liked, ignore
        }
    }

    func unlike(projectId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("project_id", value: projectId)
            .eq("user_id", value: userId)
            .execute()
    }

    func isLiked(projectId: UUID, userId: UUID) async throws -> Bool {
        let count = try await supabase
            .from("likes")
            .select("id", head: true, count: .exact)
            .eq("project_id", value: projectId)
            .eq("user_id", value: userId)
            .execute()
            .count

        return (count ?? 0) > 0
    }

    // MARK: - Collections

    func collect(projectId: UUID, userId: UUID) async throws {
        do {
            try await supabase
                .from("collections")
                .insert(["project_id": projectId.uuidString, "user_id": userId.uuidString])
                .execute()
        } catch let error as PostgrestError where error.code == "23505" {
            // Duplicate key - already collected, ignore
        }
    }

    func uncollect(projectId: UUID, userId: UUID) async throws {
        try await supabase
            .from("collections")
            .delete()
            .eq("project_id", value: projectId)
            .eq("user_id", value: userId)
            .execute()
    }

    func isCollected(projectId: UUID, userId: UUID) async throws -> Bool {
        let count = try await supabase
            .from("collections")
            .select("id", head: true, count: .exact)
            .eq("project_id", value: projectId)
            .eq("user_id", value: userId)
            .execute()
            .count

        return (count ?? 0) > 0
    }

    // MARK: - Counts

    /// Total likes received on user's projects
    func fetchLikeCount(userId: UUID) async throws -> Int {
        // Sum up like_count from all user's projects
        struct LikeSum: Decodable {
            let likeCount: Int
            enum CodingKeys: String, CodingKey {
                case likeCount = "like_count"
            }
        }

        let projects: [LikeSum] = try await supabase
            .from("projects")
            .select("like_count")
            .eq("user_id", value: userId)
            .execute()
            .value

        return projects.reduce(0) { $0 + $1.likeCount }
    }

    // MARK: - Fetch Collections

    func fetchLikedProjects(userId: UUID) async throws -> [Project] {
        // Query returns: [{ "projects": {...} }, ...]
        // Need to extract the nested projects
        struct LikeRow: Decodable {
            let projects: Project
        }

        let rows: [LikeRow] = try await supabase
            .from("likes")
            .select("projects(*, users(*))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map(\.projects)
    }

    func fetchCollectedProjects(userId: UUID) async throws -> [Project] {
        struct CollectionRow: Decodable {
            let projects: Project
        }

        let rows: [CollectionRow] = try await supabase
            .from("collections")
            .select("projects(*, users(*))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map(\.projects)
    }
}
