//
//  WorkEditorViewModel.swift
//  Swipop
//
//  Shared state for work creation/editing
//

import SwiftUI
import WebKit

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
    
    // MARK: - Cover
    
    var coverUrl: String?
    var coverImage: UIImage?  // Local image before upload
    var isCapturingCover = false
    
    /// Reference to preview WebView for screenshot capture
    weak var previewWebView: WKWebView?
    
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
    
    /// Has cover (either URL or local image)
    var hasCover: Bool {
        coverUrl != nil || coverImage != nil
    }
    
    // MARK: - Cover Actions
    
    /// Capture cover from preview WebView
    func captureCover() async {
        guard let webView = previewWebView else { return }
        
        isCapturingCover = true
        defer { isCapturingCover = false }
        
        do {
            // Capture screenshot
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds
            
            let screenshot: UIImage = try await withCheckedThrowingContinuation { continuation in
                webView.takeSnapshot(with: config) { image, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: CoverService.CoverError.noImage)
                    }
                }
            }
            
            // Crop to valid ratio immediately for accurate preview
            coverImage = CoverService.cropToValidRatio(screenshot)
            isDirty = true
        } catch {
            print("Cover capture failed: \(error)")
        }
    }
    
    /// Set cover from photo picker (auto-crops to valid ratio)
    func setCover(image: UIImage) {
        // Crop to valid ratio (4:3 ~ 3:4) immediately for accurate preview
        coverImage = CoverService.cropToValidRatio(image)
        isDirty = true
    }
    
    /// Remove cover
    func removeCover() {
        coverImage = nil
        coverUrl = nil
        isDirty = true
    }
    
    // MARK: - Actions
    
    /// Save work to database (with cover upload if needed)
    func save() async {
        guard hasContent else { return }
        
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        
        do {
            // Ensure we have a work ID for cover upload
            let effectiveWorkId: UUID
            
            if let existingId = workId {
                effectiveWorkId = existingId
            } else {
                // Create work first to get ID
                effectiveWorkId = try await WorkService.shared.createWork(
                    title: title,
                    description: description,
                    tags: tags,
                    html: html,
                    css: css,
                    javascript: javascript,
                    chatMessages: chatMessages,
                    isPublished: isPublished,
                    coverUrl: nil
                )
                workId = effectiveWorkId
            }
            
            // Upload cover if we have a local image
            var finalCoverUrl = coverUrl
            if let image = coverImage {
                finalCoverUrl = try await CoverService.shared.processAndUpload(
                    image: image,
                    workId: effectiveWorkId
                )
                coverUrl = finalCoverUrl
                coverImage = nil  // Clear local image after upload
            }
            
            // Update work with all data including cover URL
            try await WorkService.shared.updateWork(
                id: effectiveWorkId,
                title: title,
                description: description,
                tags: tags,
                html: html,
                css: css,
                javascript: javascript,
                chatMessages: chatMessages,
                isPublished: isPublished,
                coverUrl: finalCoverUrl
            )
            
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
        coverUrl = nil
        coverImage = nil
        isDirty = false
        lastSaved = nil
        saveError = nil
        previewWebView = nil
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
        coverUrl = work.thumbnailUrl
        coverImage = nil
        isDirty = false
        lastSaved = work.updatedAt
    }
    
    /// Mark as dirty when content changes
    func markDirty() {
        isDirty = true
    }
}
