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
    
    func fetchFeed(limit: Int = 10, offset: Int = 0) async throws -> [Work] {
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
            .order("updated_at", ascending: false)
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
        let chatJson = (try? JSONSerialization.data(withJSONObject: chatMessages))
            .flatMap { String(data: $0, encoding: .utf8) }
        
        var payload: [String: AnyJSON] = [
            "title": .string(title),
            "description": .string(description),
            "tags": .array(tags.map { .string($0) }),
            "html_content": .string(html),
            "css_content": .string(css),
            "js_content": .string(javascript),
            "chat_messages": chatJson.map { .string($0) } ?? .null,
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
