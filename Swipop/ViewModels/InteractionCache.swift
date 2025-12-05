//
//  InteractionCache.swift
//  Swipop
//
//  Persistent cache for like/collect states to prevent UI flashing
//  Persists to UserDefaults for instant availability on app launch
//

import Foundation

@MainActor
final class InteractionCache {
    
    static let shared = InteractionCache()
    
    private var likedWorks: Set<UUID> = []
    private var collectedWorks: Set<UUID> = []
    
    private let likedKey = "InteractionCache.likedWorks"
    private let collectedKey = "InteractionCache.collectedWorks"
    
    private init() {
        load()
    }
    
    // MARK: - Persistence
    
    private func load() {
        if let likedStrings = UserDefaults.standard.stringArray(forKey: likedKey) {
            likedWorks = Set(likedStrings.compactMap { UUID(uuidString: $0) })
        }
        if let collectedStrings = UserDefaults.standard.stringArray(forKey: collectedKey) {
            collectedWorks = Set(collectedStrings.compactMap { UUID(uuidString: $0) })
        }
    }
    
    private func save() {
        UserDefaults.standard.set(likedWorks.map { $0.uuidString }, forKey: likedKey)
        UserDefaults.standard.set(collectedWorks.map { $0.uuidString }, forKey: collectedKey)
    }
    
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
        save()
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
        save()
    }
    
    // MARK: - Bulk Update (from feed/profile data)
    
    func updateFromFeed(_ works: [Work]) {
        for work in works {
            if work.isLikedByCurrentUser == true {
                likedWorks.insert(work.id)
            }
            if work.isCollectedByCurrentUser == true {
                collectedWorks.insert(work.id)
            }
        }
        save()
    }
    
    func mergeFromLikedWorks(_ works: [Work]) {
        likedWorks.formUnion(works.map(\.id))
        save()
    }
    
    func mergeFromCollectedWorks(_ works: [Work]) {
        collectedWorks.formUnion(works.map(\.id))
        save()
    }
    
    // MARK: - Reset (on logout)
    
    func reset() {
        likedWorks.removeAll()
        collectedWorks.removeAll()
        UserDefaults.standard.removeObject(forKey: likedKey)
        UserDefaults.standard.removeObject(forKey: collectedKey)
    }
}

