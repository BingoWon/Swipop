//
//  InteractionViewModel.swift
//  Swipop
//
//  Manages like/collect state for a work with caching to prevent UI flash
//  State is preloaded from feed query, no additional network requests needed
//

import Foundation
import Auth

@Observable
final class InteractionViewModel {
    
    let work: Work
    
    private(set) var isLiked: Bool
    private(set) var isCollected: Bool
    private(set) var likeCount: Int
    private(set) var collectCount: Int
    
    private let service = InteractionService.shared
    private let auth = AuthService.shared
    private let cache = InteractionCache.shared
    
    init(work: Work) {
        self.work = work
        self.likeCount = work.likeCount
        self.collectCount = work.collectCount
        
        // Priority: Work's preloaded state > Cache > Default (false)
        // This eliminates UI flashing since state is available immediately
        if let liked = work.isLikedByCurrentUser {
            self.isLiked = liked
        } else {
            self.isLiked = cache.isLiked(work.id)
        }
        
        if let collected = work.isCollectedByCurrentUser {
            self.isCollected = collected
        } else {
            self.isCollected = cache.isCollected(work.id)
        }
    }
    
    // MARK: - Load State (only needed if not preloaded)
    
    @MainActor
    func loadState() async {
        // Skip if already loaded from feed
        if work.isLikedByCurrentUser != nil { return }
        
        guard let userId = auth.currentUser?.id else { return }
        
        do {
            async let liked = service.isLiked(workId: work.id, userId: userId)
            async let collected = service.isCollected(workId: work.id, userId: userId)
            
            let (likedResult, collectedResult) = try await (liked, collected)
            
            // Update state and cache
            isLiked = likedResult
            isCollected = collectedResult
            cache.setLiked(work.id, likedResult)
            cache.setCollected(work.id, collectedResult)
        } catch {
            print("Failed to load interaction state: \(error)")
        }
    }
    
    // MARK: - Like
    
    @MainActor
    func toggleLike() async {
        guard let userId = auth.currentUser?.id else { return }
        
        // Optimistic update
        let wasLiked = isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        cache.setLiked(work.id, isLiked)
        
        do {
            if isLiked {
                try await service.like(workId: work.id, userId: userId)
            } else {
                try await service.unlike(workId: work.id, userId: userId)
            }
        } catch {
            // Revert on failure
            isLiked = wasLiked
            likeCount += wasLiked ? 1 : -1
            cache.setLiked(work.id, wasLiked)
            print("Failed to toggle like: \(error)")
        }
    }
    
    // MARK: - Collect
    
    @MainActor
    func toggleCollect() async {
        guard let userId = auth.currentUser?.id else { return }
        
        // Optimistic update
        let wasCollected = isCollected
        isCollected.toggle()
        collectCount += isCollected ? 1 : -1
        cache.setCollected(work.id, isCollected)
        
        do {
            if isCollected {
                try await service.collect(workId: work.id, userId: userId)
            } else {
                try await service.uncollect(workId: work.id, userId: userId)
            }
        } catch {
            // Revert on failure
            isCollected = wasCollected
            collectCount += wasCollected ? 1 : -1
            cache.setCollected(work.id, wasCollected)
            print("Failed to toggle collect: \(error)")
        }
    }
}
