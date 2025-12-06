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

    func fetchComments(projectId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Comment] {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select("*, user:users!user_id(*)")
            .eq("project_id", value: projectId)
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
            .select("*, user:users!user_id(*)")
            .eq("parent_id", value: parentId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return replies
    }

    func fetchCommentCount(projectId: UUID) async throws -> Int {
        let count = try await supabase
            .from("comments")
            .select("id", head: true, count: .exact)
            .eq("project_id", value: projectId)
            .execute()
            .count

        return count ?? 0
    }

    // MARK: - Create

    func createComment(projectId: UUID, userId: UUID, content: String, parentId: UUID? = nil) async throws -> Comment {
        var data: [String: String] = [
            "project_id": projectId.uuidString,
            "user_id": userId.uuidString,
            "content": content,
        ]

        if let parentId {
            data["parent_id"] = parentId.uuidString
        }

        let comment: Comment = try await supabase
            .from("comments")
            .insert(data)
            .select("*, user:users!user_id(*)")
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
