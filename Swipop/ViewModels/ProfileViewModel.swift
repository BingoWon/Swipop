//
//  ProfileViewModel.swift
//  Swipop
//

import Foundation
import Auth

@Observable
final class ProfileViewModel {
    
    let userId: UUID
    let isCurrentUser: Bool
    
    private(set) var profile: Profile?
    private(set) var works: [Work] = []
    private(set) var likedWorks: [Work] = []
    private(set) var collectedWorks: [Work] = []
    
    private(set) var followerCount = 0
    private(set) var followingCount = 0
    private(set) var workCount = 0
    private(set) var isFollowing = false
    
    private(set) var isLoading = true
    
    private let userService = UserService.shared
    private let workService = WorkService.shared
    private let interactionService = InteractionService.shared
    
    init(userId: UUID) {
        self.userId = userId
        self.isCurrentUser = AuthService.shared.currentUser?.id == userId
    }
    
    // MARK: - Load Data
    
    @MainActor
    func load() async {
        isLoading = true
        
        async let profileTask = userService.fetchProfile(userId: userId)
        async let followerTask = userService.fetchFollowerCount(userId: userId)
        async let followingTask = userService.fetchFollowingCount(userId: userId)
        async let workCountTask = userService.fetchWorkCount(userId: userId)
        
        do {
            let (p, fc, fgc, wc) = try await (profileTask, followerTask, followingTask, workCountTask)
            
            profile = p
            followerCount = fc
            followingCount = fgc
            workCount = wc
            
            // Load works
            if isCurrentUser {
                // Current user sees all works including drafts
                works = try await workService.fetchMyWorks()
                
                // Also load liked/collected
                async let liked = interactionService.fetchLikedWorks(userId: userId)
                async let collected = interactionService.fetchCollectedWorks(userId: userId)
                
                let (l, c) = try await (liked, collected)
                likedWorks = l
                collectedWorks = c
            } else {
                // Other users only see published works
                works = try await workService.fetchUserWorks(userId: userId)
                
                if let currentUserId = AuthService.shared.currentUser?.id {
                    // Check if following this user
                    isFollowing = try await userService.isFollowing(followerId: currentUserId, followingId: userId)
                }
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh works list (called after editing)
    @MainActor
    func refreshWorks() async {
        guard isCurrentUser else { return }
        do {
            works = try await workService.fetchMyWorks()
        } catch {
            print("Failed to refresh works: \(error)")
        }
    }
    
    // MARK: - Follow
    
    @MainActor
    func toggleFollow() async {
        guard let currentUserId = AuthService.shared.currentUser?.id else { return }
        
        let wasFollowing = isFollowing
        isFollowing.toggle()
        followerCount += isFollowing ? 1 : -1
        
        do {
            if isFollowing {
                try await userService.follow(followerId: currentUserId, followingId: userId)
            } else {
                try await userService.unfollow(followerId: currentUserId, followingId: userId)
            }
        } catch {
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
            print("Failed to toggle follow: \(error)")
        }
    }
}

