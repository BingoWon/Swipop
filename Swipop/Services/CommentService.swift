//
//  CommentService.swift
//  Swipop
//

import Foundation
import Supabase

actor CommentService {
    
    static let shared = CommentService()
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch
    
    func fetchComments(workId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Comment] {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select("*, user:profiles(*)")
            .eq("work_id", value: workId)
            .is("parent_id", value: nil)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return comments
    }
    
    func fetchReplies(parentId: UUID) async throws -> [Comment] {
        let replies: [Comment] = try await supabase
            .from("comments")
            .select("*, user:profiles(*)")
            .eq("parent_id", value: parentId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return replies
    }
    
    func fetchCommentCount(workId: UUID) async throws -> Int {
        let count = try await supabase
            .from("comments")
            .select("id", head: true, count: .exact)
            .eq("work_id", value: workId)
            .execute()
            .count
        
        return count ?? 0
    }
    
    // MARK: - Create
    
    func createComment(workId: UUID, userId: UUID, content: String, parentId: UUID? = nil) async throws -> Comment {
        var data: [String: String] = [
            "work_id": workId.uuidString,
            "user_id": userId.uuidString,
            "content": content
        ]
        
        if let parentId {
            data["parent_id"] = parentId.uuidString
        }
        
        let comment: Comment = try await supabase
            .from("comments")
            .insert(data)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value
        
        return comment
    }
    
    // MARK: - Delete
    
    func deleteComment(id: UUID) async throws {
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

