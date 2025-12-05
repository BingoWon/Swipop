//
//  InteractionStore.swift
//  Swipop
//
//  Centralized state management for work interactions (like, collect)
//  Single source of truth - all views read/write from here
//

import Foundation
import Auth

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
    
    private let likedKey = "InteractionStore.likedWorks"
    private let collectedKey = "InteractionStore.collectedWorks"
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Read State
    
    func isLiked(_ workId: UUID) -> Bool {
        states[workId]?.isLiked ?? false
    }
    
    func isCollected(_ workId: UUID) -> Bool {
        states[workId]?.isCollected ?? false
    }
    
    func likeCount(_ workId: UUID) -> Int {
        states[workId]?.likeCount ?? 0
    }
    
    func collectCount(_ workId: UUID) -> Int {
        states[workId]?.collectCount ?? 0
    }
    
    // MARK: - Initialize from Works
    
    func updateFromWorks(_ works: [Work]) {
        for work in works {
            var state = states[work.id] ?? InteractionState()
            
            // Server state is authoritative
            if let liked = work.isLikedByCurrentUser {
                state.isLiked = liked
            }
            if let collected = work.isCollectedByCurrentUser {
                state.isCollected = collected
            }
            
            // Always update counts from server
            state.likeCount = work.likeCount
            state.collectCount = work.collectCount
            
            states[work.id] = state
        }
        saveToDisk()
    }
    
    // MARK: - Toggle Like
    
    func toggleLike(workId: UUID) async {
        guard let userId = auth.currentUser?.id else { return }
        
        // Get or create state
        var state = states[workId] ?? InteractionState()
        let wasLiked = state.isLiked
        
        // Optimistic update
        state.isLiked.toggle()
        state.likeCount += state.isLiked ? 1 : -1
        states[workId] = state
        saveToDisk()
        
        do {
            if state.isLiked {
                try await service.like(workId: workId, userId: userId)
            } else {
                try await service.unlike(workId: workId, userId: userId)
            }
        } catch {
            // Revert on failure
            state.isLiked = wasLiked
            state.likeCount += wasLiked ? 1 : -1
            states[workId] = state
            saveToDisk()
            print("Failed to toggle like: \(error)")
        }
    }
    
    // MARK: - Toggle Collect
    
    func toggleCollect(workId: UUID) async {
        guard let userId = auth.currentUser?.id else { return }
        
        var state = states[workId] ?? InteractionState()
        let wasCollected = state.isCollected
        
        // Optimistic update
        state.isCollected.toggle()
        state.collectCount += state.isCollected ? 1 : -1
        states[workId] = state
        saveToDisk()
        
        do {
            if state.isCollected {
                try await service.collect(workId: workId, userId: userId)
            } else {
                try await service.uncollect(workId: workId, userId: userId)
            }
        } catch {
            // Revert on failure
            state.isCollected = wasCollected
            state.collectCount += wasCollected ? 1 : -1
            states[workId] = state
            saveToDisk()
            print("Failed to toggle collect: \(error)")
        }
    }
    
    // MARK: - Update from Profile Data
    
    func updateFromLikedWorks(_ works: [Work]) {
        for work in works {
            var state = states[work.id] ?? InteractionState()
            state.isLiked = true
            state.likeCount = work.likeCount
            state.collectCount = work.collectCount
            states[work.id] = state
        }
        saveToDisk()
    }
    
    func updateFromCollectedWorks(_ works: [Work]) {
        for work in works {
            var state = states[work.id] ?? InteractionState()
            state.isCollected = true
            state.likeCount = work.likeCount
            state.collectCount = work.collectCount
            states[work.id] = state
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

