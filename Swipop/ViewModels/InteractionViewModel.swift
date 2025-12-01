//
//  InteractionViewModel.swift
//  Swipop
//
//  Manages like/collect/share state for a work
//

import Foundation
import Auth

@Observable
final class InteractionViewModel {
    
    let work: Work
    
    private(set) var isLiked = false
    private(set) var isCollected = false
    private(set) var likeCount: Int
    
    private let service = InteractionService.shared
    private let auth = AuthService.shared
    
    init(work: Work) {
        self.work = work
        self.likeCount = work.likeCount
    }
    
    // MARK: - Load State
    
    func loadState() async {
        guard let userId = auth.currentUser?.id else { return }
        
        do {
            async let liked = service.isLiked(workId: work.id, userId: userId)
            async let collected = service.isCollected(workId: work.id, userId: userId)
            
            let (likedResult, collectedResult) = try await (liked, collected)
            
            await MainActor.run {
                self.isLiked = likedResult
                self.isCollected = collectedResult
            }
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
        
        do {
            if isCollected {
                try await service.collect(workId: work.id, userId: userId)
            } else {
                try await service.uncollect(workId: work.id, userId: userId)
            }
        } catch {
            // Revert on failure
            isCollected = wasCollected
            print("Failed to toggle collect: \(error)")
        }
    }
}

