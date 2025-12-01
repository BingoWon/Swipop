//
//  WorkService.swift
//  Swipop
//
//  Service for fetching and managing works
//

import Foundation
import Supabase

actor WorkService {
    
    // MARK: - Singleton
    
    static let shared = WorkService()
    
    // MARK: - Private
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Works
    
    /// Select query with joined creator profile
    private let selectWithCreator = "*, profiles(*)"
    
    func fetchFeed(limit: Int = 10, offset: Int = 0) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return works
    }
    
    func fetchWork(id: UUID) async throws -> Work {
        let work: Work = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return work
    }
    
    func fetchUserWorks(userId: UUID) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return works
    }
    
    // MARK: - Create / Update
    
    func createWork(_ work: Work) async throws -> Work {
        let created: Work = try await supabase
            .from("works")
            .insert(work)
            .select()
            .single()
            .execute()
            .value
        
        return created
    }
    
    func updateWork(_ work: Work) async throws -> Work {
        let updated: Work = try await supabase
            .from("works")
            .update(work)
            .eq("id", value: work.id)
            .select()
            .single()
            .execute()
            .value
        
        return updated
    }
    
    func deleteWork(id: UUID) async throws {
        try await supabase
            .from("works")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

