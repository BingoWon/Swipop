//
//  WorkEditorViewModel.swift
//  Swipop
//
//  Shared state for work creation/editing
//

import SwiftUI

@MainActor
@Observable
final class WorkEditorViewModel {
    
    // MARK: - Identity
    
    /// Work ID (nil for new unsaved work)
    var workId: UUID?
    
    // MARK: - Content
    
    var html = "" { didSet { if html != oldValue { isDirty = true } } }
    var css = "" { didSet { if css != oldValue { isDirty = true } } }
    var javascript = "" { didSet { if javascript != oldValue { isDirty = true } } }
    
    // MARK: - Chat
    
    /// Chat messages for this work (stored as JSON)
    var chatMessages: [[String: Any]] = []
    
    // MARK: - Metadata
    
    var title = "" { didSet { if title != oldValue { isDirty = true } } }
    var description = "" { didSet { if description != oldValue { isDirty = true } } }
    var tags: [String] = [] { didSet { if tags != oldValue { isDirty = true } } }
    var isPublished = false { didSet { if isPublished != oldValue { isDirty = true } } }
    
    // MARK: - State
    
    var isDirty = false
    var isSaving = false
    var lastSaved: Date?
    var saveError: Error?
    
    // MARK: - Computed
    
    /// Check if code files have any content
    var hasCode: Bool {
        !html.isEmpty || !css.isEmpty || !javascript.isEmpty
    }
    
    /// Check if metadata has any content
    var hasMetadata: Bool {
        !title.isEmpty || !description.isEmpty || !tags.isEmpty
    }
    
    /// Check if chat has any messages (excluding system prompt)
    var hasChat: Bool {
        chatMessages.contains { ($0["role"] as? String) != "system" }
    }
    
    /// Work exists if any content is present
    /// 作品存在条件 = 会话非空 ∨ Metadata非空 ∨ 代码非空
    var hasContent: Bool {
        hasChat || hasMetadata || hasCode
    }
    
    /// Whether this is a new work (not yet saved to database)
    var isNew: Bool { workId == nil }
    
    // MARK: - Actions
    
    /// Save work to database
    func save() async {
        guard hasContent else { return }
        
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        
        do {
            if let existingId = workId {
                // Update existing work
                try await WorkService.shared.updateWork(
                    id: existingId,
                    title: title,
                    description: description,
                    tags: tags,
                    html: html,
                    css: css,
                    javascript: javascript,
                    chatMessages: chatMessages,
                    isPublished: isPublished
                )
            } else {
                // Create new work
                let newId = try await WorkService.shared.createWork(
                    title: title,
                    description: description,
                    tags: tags,
                    html: html,
                    css: css,
                    javascript: javascript,
                    chatMessages: chatMessages,
                    isPublished: isPublished
                )
                workId = newId
            }
            
            isDirty = false
            lastSaved = Date()
        } catch {
            saveError = error
        }
    }
    
    /// Save if has content, then reset
    func saveAndReset() async {
        if hasContent {
            await save()
        }
        reset()
    }
    
    /// Reset to empty state for new work
    func reset() {
        workId = nil
        html = ""
        css = ""
        javascript = ""
        chatMessages = []
        title = ""
        description = ""
        tags = []
        isPublished = false
        isDirty = false
        lastSaved = nil
        saveError = nil
    }
    
    /// Load work from database
    func load(work: Work) {
        workId = work.id
        title = work.title
        description = work.description ?? ""
        tags = work.tags ?? []
        html = work.htmlContent ?? ""
        css = work.cssContent ?? ""
        javascript = work.jsContent ?? ""
        chatMessages = work.chatMessages ?? []
        isPublished = work.isPublished
        isDirty = false
        lastSaved = work.updatedAt
    }
    
    /// Mark as dirty when content changes
    func markDirty() {
        isDirty = true
    }
}
