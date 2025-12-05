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
    
    func like(workId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .insert(["work_id": workId.uuidString, "user_id": userId.uuidString])
            .execute()
    }
    
    func unlike(workId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("work_id", value: workId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func isLiked(workId: UUID, userId: UUID) async throws -> Bool {
        let count = try await supabase
            .from("likes")
            .select("id", head: true, count: .exact)
            .eq("work_id", value: workId)
            .eq("user_id", value: userId)
            .execute()
            .count
        
        return (count ?? 0) > 0
    }
    
    // MARK: - Collections
    
    func collect(workId: UUID, userId: UUID) async throws {
        try await supabase
            .from("collections")
            .insert(["work_id": workId.uuidString, "user_id": userId.uuidString])
            .execute()
    }
    
    func uncollect(workId: UUID, userId: UUID) async throws {
        try await supabase
            .from("collections")
            .delete()
            .eq("work_id", value: workId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func isCollected(workId: UUID, userId: UUID) async throws -> Bool {
        let count = try await supabase
            .from("collections")
            .select("id", head: true, count: .exact)
            .eq("work_id", value: workId)
            .eq("user_id", value: userId)
            .execute()
            .count
        
        return (count ?? 0) > 0
    }
    
    // MARK: - Counts
    
    /// Total likes received on user's works
    func fetchLikeCount(userId: UUID) async throws -> Int {
        // Sum up like_count from all user's works
        struct LikeSum: Decodable {
            let likeCount: Int
            enum CodingKeys: String, CodingKey {
                case likeCount = "like_count"
            }
        }
        
        let works: [LikeSum] = try await supabase
            .from("works")
            .select("like_count")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return works.reduce(0) { $0 + $1.likeCount }
    }
    
    // MARK: - Fetch Collections
    
    func fetchLikedWorks(userId: UUID) async throws -> [Work] {
        // Query returns: [{ "works": {...} }, ...]
        // Need to extract the nested works
        struct LikeRow: Decodable {
            let works: Work
        }
        
        let rows: [LikeRow] = try await supabase
            .from("likes")
            .select("works(*, users(*))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows.map(\.works)
    }
    
    func fetchCollectedWorks(userId: UUID) async throws -> [Work] {
        struct CollectionRow: Decodable {
            let works: Work
        }
        
        let rows: [CollectionRow] = try await supabase
            .from("collections")
            .select("works(*, users(*))")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows.map(\.works)
    }
}

