//
//  InteractionStore.swift
//  Swipop
//
//  Centralized state management for project interactions (like, collect)
//  Single source of truth - all views read/write from here
//

import Auth
import Foundation

@MainActor
@Observable
final class InteractionStore {
    static let shared = InteractionStore()

    // MARK: - State

    private var states: [UUID: InteractionState] = [:]

    // MARK: - Services

    private let service = InteractionService.shared
    private let auth = AuthService.shared

    // MARK: - Persistence Keys

    private let likedKey = "InteractionStore.likedProjects"
    private let collectedKey = "InteractionStore.collectedProjects"

    private init() {
        loadFromDisk()
    }

    // MARK: - Read State

    func isLiked(_ projectId: UUID) -> Bool {
        states[projectId]?.isLiked ?? false
    }

    func isCollected(_ projectId: UUID) -> Bool {
        states[projectId]?.isCollected ?? false
    }

    func likeCount(_ projectId: UUID) -> Int {
        states[projectId]?.likeCount ?? 0
    }

    func collectCount(_ projectId: UUID) -> Int {
        states[projectId]?.collectCount ?? 0
    }

    // MARK: - Initialize from Projects

    func updateFromProjects(_ projects: [Project]) {
        for project in projects {
            var state = states[project.id] ?? InteractionState()

            // Server state is authoritative
            if let liked = project.isLikedByCurrentUser {
                state.isLiked = liked
            }
            if let collected = project.isCollectedByCurrentUser {
                state.isCollected = collected
            }

            // Always update counts from server
            state.likeCount = project.likeCount
            state.collectCount = project.collectCount

            states[project.id] = state
        }
        saveToDisk()
    }

    // MARK: - Toggle Like

    func toggleLike(projectId: UUID) async {
        guard let userId = auth.currentUser?.id else { return }

        // Get or create state
        var state = states[projectId] ?? InteractionState()
        let wasLiked = state.isLiked

        // Optimistic update
        state.isLiked.toggle()
        state.likeCount += state.isLiked ? 1 : -1
        states[projectId] = state
        saveToDisk()

        do {
            if state.isLiked {
                try await service.like(projectId: projectId, userId: userId)
            } else {
                try await service.unlike(projectId: projectId, userId: userId)
            }
        } catch {
            // Revert on failure
            state.isLiked = wasLiked
            state.likeCount += wasLiked ? 1 : -1
            states[projectId] = state
            saveToDisk()
            print("Failed to toggle like: \(error)")
        }
    }

    // MARK: - Toggle Collect

    func toggleCollect(projectId: UUID) async {
        guard let userId = auth.currentUser?.id else { return }

        var state = states[projectId] ?? InteractionState()
        let wasCollected = state.isCollected

        // Optimistic update
        state.isCollected.toggle()
        state.collectCount += state.isCollected ? 1 : -1
        states[projectId] = state
        saveToDisk()

        do {
            if state.isCollected {
                try await service.collect(projectId: projectId, userId: userId)
            } else {
                try await service.uncollect(projectId: projectId, userId: userId)
            }
        } catch {
            // Revert on failure
            state.isCollected = wasCollected
            state.collectCount += wasCollected ? 1 : -1
            states[projectId] = state
            saveToDisk()
            print("Failed to toggle collect: \(error)")
        }
    }

    // MARK: - Update from Profile Data

    func updateFromProfileData(liked: [Project], collected: [Project]) {
        for project in liked {
            var state = states[project.id] ?? InteractionState()
            state.isLiked = true
            state.likeCount = project.likeCount
            state.collectCount = project.collectCount
            states[project.id] = state
        }
        for project in collected {
            var state = states[project.id] ?? InteractionState()
            state.isCollected = true
            state.likeCount = project.likeCount
            state.collectCount = project.collectCount
            states[project.id] = state
        }
        saveToDisk()
    }

    // MARK: - Reset (on logout)

    func reset() {
        states.removeAll()
        UserDefaults.standard.removeObject(forKey: likedKey)
        UserDefaults.standard.removeObject(forKey: collectedKey)
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        if let likedStrings = UserDefaults.standard.stringArray(forKey: likedKey) {
            for idString in likedStrings {
                if let id = UUID(uuidString: idString) {
                    var state = states[id] ?? InteractionState()
                    state.isLiked = true
                    states[id] = state
                }
            }
        }
        if let collectedStrings = UserDefaults.standard.stringArray(forKey: collectedKey) {
            for idString in collectedStrings {
                if let id = UUID(uuidString: idString) {
                    var state = states[id] ?? InteractionState()
                    state.isCollected = true
                    states[id] = state
                }
            }
        }
    }

    private func saveToDisk() {
        let likedIds = states.filter { $0.value.isLiked }.map { $0.key.uuidString }
        let collectedIds = states.filter { $0.value.isCollected }.map { $0.key.uuidString }
        UserDefaults.standard.set(likedIds, forKey: likedKey)
        UserDefaults.standard.set(collectedIds, forKey: collectedKey)
    }
}

// MARK: - Interaction State

private struct InteractionState {
    var isLiked: Bool = false
    var isCollected: Bool = false
    var likeCount: Int = 0
    var collectCount: Int = 0
}
