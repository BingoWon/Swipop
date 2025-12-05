//
//  InteractionCache.swift
//  Swipop
//
//  Global cache for like/collect states to prevent UI flashing
//

import Foundation

@MainActor
final class InteractionCache {
    
    static let shared = InteractionCache()
    
    private var likedWorks: Set<UUID> = []
    private var collectedWorks: Set<UUID> = []
    
    private init() {}
    
    // MARK: - Like
    
    func isLiked(_ workId: UUID) -> Bool {
        likedWorks.contains(workId)
    }
    
    func setLiked(_ workId: UUID, _ value: Bool) {
        if value {
            likedWorks.insert(workId)
        } else {
            likedWorks.remove(workId)
        }
    }
    
    // MARK: - Collect
    
    func isCollected(_ workId: UUID) -> Bool {
        collectedWorks.contains(workId)
    }
    
    func setCollected(_ workId: UUID, _ value: Bool) {
        if value {
            collectedWorks.insert(workId)
        } else {
            collectedWorks.remove(workId)
        }
    }
    
    // MARK: - Merge (from profile data, preserves local state)
    
    func mergeFromLikedWorks(_ works: [Work]) {
        likedWorks.formUnion(works.map(\.id))
    }
    
    func mergeFromCollectedWorks(_ works: [Work]) {
        collectedWorks.formUnion(works.map(\.id))
    }
    
    // MARK: - Reset
    
    func reset() {
        likedWorks.removeAll()
        collectedWorks.removeAll()
    }
}

