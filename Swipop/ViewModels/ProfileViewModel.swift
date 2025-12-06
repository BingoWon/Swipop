//
//  ProfileViewModel.swift
//  Swipop
//

import Auth
import Foundation

// MARK: - Current User Profile (Singleton with preloading)

@MainActor
@Observable
final class CurrentUserProfile {
    static let shared = CurrentUserProfile()

    private(set) var profile: Profile?
    private(set) var projects: [Project] = []
    private(set) var likedProjects: [Project] = []
    private(set) var collectedProjects: [Project] = []

    private(set) var followerCount = 0
    private(set) var followingCount = 0
    private(set) var projectCount = 0
    private(set) var likeCount = 0

    /// True during initial load (no data yet)
    private(set) var isLoading = false
    /// True during background refresh (has data, updating)
    private(set) var isRefreshing = false
    /// True if data has been loaded at least once
    private(set) var hasLoaded = false

    private let userService = UserService.shared
    private let projectService = ProjectService.shared
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
        projects = []
        likedProjects = []
        collectedProjects = []
        followerCount = 0
        followingCount = 0
        projectCount = 0
        likeCount = 0
        hasLoaded = false
    }

    private func fetchData(userId: UUID) async {
        async let profileTask = userService.fetchProfile(userId: userId)
        async let followerTask = userService.fetchFollowerCount(userId: userId)
        async let followingTask = userService.fetchFollowingCount(userId: userId)
        async let projectCountTask = userService.fetchProjectCount(userId: userId)
        async let likeCountTask = interactionService.fetchLikeCount(userId: userId)
        async let projectsTask = projectService.fetchMyProjects()
        async let likedTask = interactionService.fetchLikedProjects(userId: userId)
        async let collectedTask = interactionService.fetchCollectedProjects(userId: userId)

        do {
            let (p, fc, fgc, pc, lc, proj, l, c) = try await (
                profileTask, followerTask, followingTask, projectCountTask, likeCountTask,
                projectsTask, likedTask, collectedTask
            )

            profile = p
            followerCount = fc
            followingCount = fgc
            projectCount = pc
            likeCount = lc
            projects = proj
            likedProjects = l
            collectedProjects = c

            // Update interaction store with liked/collected states
            InteractionStore.shared.updateFromProfileData(liked: l, collected: c)
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
    private(set) var projects: [Project] = []

    private(set) var followerCount = 0
    private(set) var followingCount = 0
    private(set) var projectCount = 0
    private(set) var likeCount = 0
    private(set) var isFollowing = false

    private(set) var isLoading = true

    /// True if viewing own profile (should not show Follow button)
    var isSelf: Bool {
        AuthService.shared.currentUser?.id == userId
    }

    private let userService = UserService.shared
    private let projectService = ProjectService.shared
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
        async let projectCountTask = userService.fetchProjectCount(userId: userId)
        async let likeCountTask = interactionService.fetchLikeCount(userId: userId)
        async let projectsTask = projectService.fetchUserProjects(userId: userId)

        do {
            let (p, fc, fgc, pc, lc, proj) = try await (
                profileTask, followerTask, followingTask, projectCountTask, likeCountTask, projectsTask
            )

            profile = p
            followerCount = fc
            followingCount = fgc
            projectCount = pc
            likeCount = lc
            projects = proj

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
