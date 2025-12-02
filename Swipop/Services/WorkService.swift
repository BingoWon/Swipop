//
//  WorkService.swift
//  Swipop
//
//  Service for fetching and managing works
//

import Foundation
import Supabase

actor WorkService {
    
    // MARK: - Singleton
    
    static let shared = WorkService()
    
    // MARK: - Private
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Works
    
    /// Select query with joined creator profile
    private let selectWithCreator = "*, profiles(*)"
    
    func fetchFeed(limit: Int = 10, offset: Int = 0) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("is_published", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return works
    }
    
    func fetchWork(id: UUID) async throws -> Work {
        let work: Work = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return work
    }
    
    func fetchUserWorks(userId: UUID) async throws -> [Work] {
        let works: [Work] = try await supabase
            .from("works")
            .select(selectWithCreator)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return works
    }
    
    /// Fetch current user's works (including drafts)
    func fetchMyWorks() async throws -> [Work] {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw WorkError.notAuthenticated
        }
        
        let works: [Work] = try await supabase
            .from("works")
            .select("*")
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        return works
    }
    
    // MARK: - Create / Update (for WorkEditorViewModel)
    
    /// Create a new work and return its ID
    func createWork(
        title: String,
        description: String,
        tags: [String],
        html: String,
        css: String,
        javascript: String,
        chatMessages: [[String: Any]],
        isPublished: Bool
    ) async throws -> UUID {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw WorkError.notAuthenticated
        }
        
        // Serialize chat messages to JSON
        let chatData = try? JSONSerialization.data(withJSONObject: chatMessages)
        let chatString = chatData.flatMap { String(data: $0, encoding: .utf8) }
        
        let payload: [String: AnyJSON] = [
            "user_id": .string(userId.uuidString),
            "title": .string(title),
            "description": .string(description),
            "tags": .array(tags.map { .string($0) }),
            "html_content": .string(html),
            "css_content": .string(css),
            "js_content": .string(javascript),
            "chat_messages": chatString.map { .string($0) } ?? .null,
            "is_published": .bool(isPublished)
        ]
        
        struct InsertResult: Decodable {
            let id: UUID
        }
        
        let result: InsertResult = try await supabase
            .from("works")
            .insert(payload)
            .select("id")
            .single()
            .execute()
            .value
        
        return result.id
    }
    
    /// Update an existing work
    func updateWork(
        id: UUID,
        title: String,
        description: String,
        tags: [String],
        html: String,
        css: String,
        javascript: String,
        chatMessages: [[String: Any]],
        isPublished: Bool
    ) async throws {
        // Serialize chat messages to JSON
        let chatData = try? JSONSerialization.data(withJSONObject: chatMessages)
        let chatString = chatData.flatMap { String(data: $0, encoding: .utf8) }
        
        let payload: [String: AnyJSON] = [
            "title": .string(title),
            "description": .string(description),
            "tags": .array(tags.map { .string($0) }),
            "html_content": .string(html),
            "css_content": .string(css),
            "js_content": .string(javascript),
            "chat_messages": chatString.map { .string($0) } ?? .null,
            "is_published": .bool(isPublished),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("works")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }
    
    func deleteWork(id: UUID) async throws {
        try await supabase
            .from("works")
            .delete()
            .eq("id", value: id)
            .execute()
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

