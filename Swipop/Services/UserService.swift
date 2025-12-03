//
//  UserService.swift
//  Swipop
//

import Foundation
import Supabase

actor UserService {
    
    static let shared = UserService()
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Profile
    
    func fetchProfile(userId: UUID) async throws -> Profile {
        let profile: Profile = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        let payload = ProfileUpdatePayload(
            username: profile.username,
            displayName: profile.displayName,
            bio: profile.bio,
            links: profile.links
        )
        
        let updated: Profile = try await supabase
            .from("users")
            .update(payload)
            .eq("id", value: profile.id)
            .select()
            .single()
            .execute()
            .value
        
        return updated
    }
    
    // MARK: - Stats
    
    func fetchFollowerCount(userId: UUID) async throws -> Int {
        let count = try await supabase
            .from("follows")
            .select("id", head: true, count: .exact)
            .eq("following_id", value: userId)
            .execute()
            .count
        
        return count ?? 0
    }
    
    func fetchFollowingCount(userId: UUID) async throws -> Int {
        let count = try await supabase
            .from("follows")
            .select("id", head: true, count: .exact)
            .eq("follower_id", value: userId)
            .execute()
            .count
        
        return count ?? 0
    }
    
    func fetchWorkCount(userId: UUID) async throws -> Int {
        let count = try await supabase
            .from("works")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("is_published", value: true)
            .execute()
            .count
        
        return count ?? 0
    }
    
    // MARK: - Follow
    
    func follow(followerId: UUID, followingId: UUID) async throws {
        try await supabase
            .from("follows")
            .insert(["follower_id": followerId.uuidString, "following_id": followingId.uuidString])
            .execute()
    }
    
    func unfollow(followerId: UUID, followingId: UUID) async throws {
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
    }
    
    func isFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
        let count = try await supabase
            .from("follows")
            .select("id", head: true, count: .exact)
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
            .count
        
        return (count ?? 0) > 0
    }
}

// MARK: - Profile Update Payload

private struct ProfileUpdatePayload: Encodable {
    let username: String?
    let displayName: String?
    let bio: String?
    let links: [ProfileLink]
    
    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case bio
        case links
    }
}
