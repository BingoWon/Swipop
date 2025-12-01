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
    
    // MARK: - Fetch Collections
    
    func fetchLikedWorks(userId: UUID) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("likes")
            .select("works(*)")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return works
    }
    
    func fetchCollectedWorks(userId: UUID) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("collections")
            .select("works(*)")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return works
    }
}

