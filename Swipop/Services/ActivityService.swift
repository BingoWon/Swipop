//
//  ActivityService.swift
//  Swipop
//
//  Service for fetching and managing user activity notifications
//

import Foundation
import Supabase

actor ActivityService {
    
    // MARK: - Singleton
    
    static let shared = ActivityService()
    
    // MARK: - Private
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Activities
    
    func fetchActivities(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Activity] {
        let activities: [Activity] = try await supabase
            .from("activities")
            .select("*, actor:users!actor_id(*), work:works(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return activities
    }
    
    // MARK: - Unread Count
    
    func fetchUnreadCount(userId: UUID) async throws -> Int {
        let count = try await supabase
            .from("activities")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
            .count
        
        return count ?? 0
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(activityId: UUID) async throws {
        try await supabase
            .from("activities")
            .update(["is_read": true])
            .eq("id", value: activityId)
            .execute()
    }
    
    func markAllAsRead(userId: UUID) async throws {
        try await supabase
            .from("activities")
            .update(["is_read": true])
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }
}

