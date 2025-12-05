//
//  WorkService.swift
//  Swipop
//
//  Service for fetching and managing works
//

import Foundation
import Supabase

actor WorkService {
    
    static let shared = WorkService()
    
    private let supabase = SupabaseService.shared.client
    private let selectWithCreator = "*, users(*)"
    
    private init() {}
    
    // MARK: - Fetch
    
    /// Fetch feed with current user's interaction states (is_liked, is_collected)
    /// Uses RPC for single-query efficiency
    func fetchFeed(limit: Int = 10, offset: Int = 0, userId: UUID? = nil) async throws -> [Work] {
        // Build params - Supabase expects snake_case
        var params: [String: AnyJSON] = [
            "p_limit": .integer(limit),
            "p_offset": .integer(offset)
        ]
        
        if let userId {
            params["p_user_id"] = .string(userId.uuidString)
        }
        
        let rows: [FeedWorkRow] = try await supabase
            .rpc("get_feed_with_interactions", params: params)
            .execute()
            .value
        
        return rows.map { $0.toWork() }
    }
    
    /// Legacy fetch without interaction states (for non-authenticated users or fallback)
    func fetchFeedBasic(limit: Int = 10, offset: Int = 0) async throws -> [Work] {
        try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }
    
    func fetchWork(id: UUID) async throws -> Work {
        try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
    
    func fetchUserWorks(userId: UUID) async throws -> [Work] {
        try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func fetchMyWorks() async throws -> [Work] {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw WorkError.notAuthenticated
        }
        
        return try await supabase
            .from("works")
            .select("*")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    // MARK: - Create / Update / Delete
    
    func createWork(
        title: String,
        description: String,
        tags: [String],
        html: String,
        css: String,
        javascript: String,
        chatMessages: [[String: Any]],
        isPublished: Bool,
        thumbnailUrl: String? = nil,
        thumbnailAspectRatio: CGFloat? = nil
    ) async throws -> UUID {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw WorkError.notAuthenticated
        }
        
        var payload = buildPayload(
            title: title, description: description, tags: tags,
            html: html, css: css, javascript: javascript,
            chatMessages: chatMessages, isPublished: isPublished,
            thumbnailUrl: thumbnailUrl, thumbnailAspectRatio: thumbnailAspectRatio
        )
        payload["user_id"] = .string(userId.uuidString)
        
        struct InsertResult: Decodable { let id: UUID }
        
        let result: InsertResult = try await supabase
            .from("works")
            .insert(payload)
            .select("id")
            .single()
            .execute()
            .value
        
        return result.id
    }
    
    func updateWork(
        id: UUID,
        title: String,
        description: String,
        tags: [String],
        html: String,
        css: String,
        javascript: String,
        chatMessages: [[String: Any]],
        isPublished: Bool,
        thumbnailUrl: String? = nil,
        thumbnailAspectRatio: CGFloat? = nil
    ) async throws {
        var payload = buildPayload(
            title: title, description: description, tags: tags,
            html: html, css: css, javascript: javascript,
            chatMessages: chatMessages, isPublished: isPublished,
            thumbnailUrl: thumbnailUrl, thumbnailAspectRatio: thumbnailAspectRatio
        )
        payload["updated_at"] = .string(ISO8601DateFormatter().string(from: Date()))
        
        try await supabase
            .from("works")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }
    
    func deleteWork(id: UUID) async throws {
        try? await ThumbnailService.shared.delete(workId: id)
        
        try await supabase
            .from("works")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Private
    
    private func buildPayload(
        title: String,
        description: String,
        tags: [String],
        html: String,
        css: String,
        javascript: String,
        chatMessages: [[String: Any]],
        isPublished: Bool,
        thumbnailUrl: String?,
        thumbnailAspectRatio: CGFloat?
    ) -> [String: AnyJSON] {
        // Convert chat messages to native AnyJSON array (not string!)
        let chatJsonArray: AnyJSON = .array(chatMessages.map { messageDict -> AnyJSON in
            .object(messageDict.compactMapValues { value -> AnyJSON? in
                if let string = value as? String { return .string(string) }
                if let int = value as? Int { return .integer(int) }
                if let double = value as? Double { return .double(double) }
                if let bool = value as? Bool { return .bool(bool) }
                if let array = value as? [Any] {
                    // Handle nested arrays (like tool_calls)
                    if let data = try? JSONSerialization.data(withJSONObject: array),
                       let json = try? JSONDecoder().decode(AnyJSON.self, from: data) {
                        return json
                    }
                }
                if let dict = value as? [String: Any] {
                    // Handle nested dictionaries
                    if let data = try? JSONSerialization.data(withJSONObject: dict),
                       let json = try? JSONDecoder().decode(AnyJSON.self, from: data) {
                        return json
                    }
                }
                return nil
            })
        })
        
        var payload: [String: AnyJSON] = [
            "title": .string(title),
            "description": .string(description),
            "tags": .array(tags.map { .string($0) }),
            "html_content": .string(html),
            "css_content": .string(css),
            "js_content": .string(javascript),
            "chat_messages": chatJsonArray,
            "is_published": .bool(isPublished)
        ]
        
        if let thumbnailUrl {
            payload["thumbnail_url"] = .string(thumbnailUrl)
        }
        
        if let thumbnailAspectRatio {
            payload["thumbnail_aspect_ratio"] = .double(Double(thumbnailAspectRatio))
        }
        
        return payload
    }
    
    // MARK: - Errors
    
    enum WorkError: LocalizedError {
        case notAuthenticated
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: "Please sign in to save works"
            }
        }
    }
}
