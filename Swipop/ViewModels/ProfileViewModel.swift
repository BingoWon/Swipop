//
//  ProfileViewModel.swift
//  Swipop
//

import Foundation
import Auth

// MARK: - Current User Profile (Singleton with preloading)

@MainActor
@Observable
final class CurrentUserProfile {
    
    static let shared = CurrentUserProfile()
    
    private(set) var profile: Profile?
    private(set) var works: [Work] = []
    private(set) var likedWorks: [Work] = []
    private(set) var collectedWorks: [Work] = []
    
    private(set) var followerCount = 0
    private(set) var followingCount = 0
    private(set) var workCount = 0
    private(set) var likeCount = 0
    
    /// True during initial load (no data yet)
    private(set) var isLoading = false
    /// True during background refresh (has data, updating)
    private(set) var isRefreshing = false
    /// True if data has been loaded at least once
    private(set) var hasLoaded = false
    
    private let userService = UserService.shared
    private let workService = WorkService.shared
    private let interactionService = InteractionService.shared
    
    private init() {}
    
    /// Preload after login - call from AuthService
    func preload() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await fetchData(userId: userId)
        hasLoaded = true
    }
    
    /// Refresh when entering Profile tab
    func refresh() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        // If never loaded, do initial load
        guard hasLoaded else {
            await preload()
            return
        }
        
        // Background refresh with indicator
        isRefreshing = true
        defer { isRefreshing = false }
        
        await fetchData(userId: userId)
    }
    
    /// Reset on logout
    func reset() {
        profile = nil
        works = []
        likedWorks = []
        collectedWorks = []
        followerCount = 0
        followingCount = 0
        workCount = 0
        likeCount = 0
        hasLoaded = false
    }
    
    private func fetchData(userId: UUID) async {
        async let profileTask = userService.fetchProfile(userId: userId)
        async let followerTask = userService.fetchFollowerCount(userId: userId)
        async let followingTask = userService.fetchFollowingCount(userId: userId)
        async let workCountTask = userService.fetchWorkCount(userId: userId)
        async let likeCountTask = interactionService.fetchLikeCount(userId: userId)
        async let worksTask = workService.fetchMyWorks()
        async let likedTask = interactionService.fetchLikedWorks(userId: userId)
        async let collectedTask = interactionService.fetchCollectedWorks(userId: userId)
        
        do {
            let (p, fc, fgc, wc, lc, w, l, c) = try await (
                profileTask, followerTask, followingTask, workCountTask, likeCountTask,
                worksTask, likedTask, collectedTask
            )
            
            profile = p
            followerCount = fc
            followingCount = fgc
            workCount = wc
            likeCount = lc
            works = w
            likedWorks = l
            collectedWorks = c
            
            // Merge into interaction cache to prevent UI flash
            InteractionCache.shared.mergeFromLikedWorks(l)
            InteractionCache.shared.mergeFromCollectedWorks(c)
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}

// MARK: - Other User Profile (for viewing others)

@MainActor
@Observable
final class OtherUserProfileViewModel {
    
    let userId: UUID
    
    private(set) var profile: Profile?
    private(set) var works: [Work] = []
    
    private(set) var followerCount = 0
    private(set) var followingCount = 0
    private(set) var workCount = 0
    private(set) var likeCount = 0
    private(set) var isFollowing = false
    
    private(set) var isLoading = true
    
    /// True if viewing own profile (should not show Follow button)
    var isSelf: Bool {
        AuthService.shared.currentUser?.id == userId
    }
    
    private let userService = UserService.shared
    private let workService = WorkService.shared
    private let interactionService = InteractionService.shared
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        async let profileTask = userService.fetchProfile(userId: userId)
        async let followerTask = userService.fetchFollowerCount(userId: userId)
        async let followingTask = userService.fetchFollowingCount(userId: userId)
        async let workCountTask = userService.fetchWorkCount(userId: userId)
        async let likeCountTask = interactionService.fetchLikeCount(userId: userId)
        async let worksTask = workService.fetchUserWorks(userId: userId)
        
        do {
            let (p, fc, fgc, wc, lc, w) = try await (
                profileTask, followerTask, followingTask, workCountTask, likeCountTask, worksTask
            )
            
            profile = p
            followerCount = fc
            followingCount = fgc
            workCount = wc
            likeCount = lc
            works = w
            
            // Only check follow status if not viewing self
            if let currentUserId = AuthService.shared.currentUser?.id, currentUserId != userId {
                isFollowing = try await userService.isFollowing(followerId: currentUserId, followingId: userId)
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    func toggleFollow() async {
        guard let currentUserId = AuthService.shared.currentUser?.id,
              currentUserId != userId else { return } // Prevent self-follow
        
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

