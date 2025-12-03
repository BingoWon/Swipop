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
    
    var workId: UUID?
    
    // MARK: - Content
    
    var html = "" { didSet { if html != oldValue { isDirty = true } } }
    var css = "" { didSet { if css != oldValue { isDirty = true } } }
    var javascript = "" { didSet { if javascript != oldValue { isDirty = true } } }
    
    // MARK: - Chat
    
    var chatMessages: [[String: Any]] = []
    
    // MARK: - Metadata
    
    var title = "" { didSet { if title != oldValue { isDirty = true } } }
    var description = "" { didSet { if description != oldValue { isDirty = true } } }
    var tags: [String] = [] { didSet { if tags != oldValue { isDirty = true } } }
    var isPublished = false { didSet { if isPublished != oldValue { isDirty = true } } }
    
    // MARK: - Thumbnail
    
    var thumbnailUrl: String?
    var thumbnailAspectRatio: CGFloat?
    var thumbnailImage: UIImage?
    var isCapturingThumbnail = false
    
    weak var previewWebView: WKWebView?
    
    // MARK: - State
    
    var isDirty = false
    var isSaving = false
    var lastSaved: Date?
    var saveError: Error?
    
    // MARK: - Computed
    
    var hasCode: Bool { !html.isEmpty || !css.isEmpty || !javascript.isEmpty }
    var hasMetadata: Bool { !title.isEmpty || !description.isEmpty || !tags.isEmpty }
    var hasChat: Bool { chatMessages.contains { ($0["role"] as? String) != "system" } }
    var hasContent: Bool { hasChat || hasMetadata || hasCode }
    var isNew: Bool { workId == nil }
    var hasThumbnail: Bool { thumbnailUrl != nil || thumbnailImage != nil }
    
    // MARK: - Thumbnail Actions
    
    func captureThumbnail() async {
        guard let webView = previewWebView else { return }
        
        isCapturingThumbnail = true
        defer { isCapturingThumbnail = false }
        
        do {
            let cropped = try await ThumbnailService.shared.capture(from: webView)
            thumbnailImage = cropped
            thumbnailAspectRatio = cropped.size.width / cropped.size.height
            isDirty = true
        } catch {
            saveError = error
        }
    }
    
    func setThumbnail(image: UIImage) {
        let cropped = ThumbnailService.cropToValidRatio(image)
        thumbnailImage = cropped
        thumbnailAspectRatio = cropped.size.width / cropped.size.height
        isDirty = true
    }
    
    func removeThumbnail() {
        thumbnailImage = nil
        thumbnailUrl = nil
        thumbnailAspectRatio = nil
        isDirty = true
    }
    
    // MARK: - Save
    
    func save() async {
        guard hasContent else { return }
        
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        
        do {
            // Create work if new
            let effectiveWorkId: UUID
            if let existingId = workId {
                effectiveWorkId = existingId
            } else {
                effectiveWorkId = try await WorkService.shared.createWork(
                    title: title, description: description, tags: tags,
                    html: html, css: css, javascript: javascript,
                    chatMessages: chatMessages, isPublished: isPublished,
                    thumbnailUrl: nil, thumbnailAspectRatio: nil
                )
                workId = effectiveWorkId
            }
            
            // Upload thumbnail if needed
            var finalThumbnailUrl = thumbnailUrl
            var finalAspectRatio = thumbnailAspectRatio
            
            if let image = thumbnailImage {
                let result = try await ThumbnailService.shared.upload(image: image, workId: effectiveWorkId)
                finalThumbnailUrl = result.url
                finalAspectRatio = result.aspectRatio
                thumbnailUrl = result.url
                thumbnailAspectRatio = result.aspectRatio
                thumbnailImage = nil
            }
            
            // Update work
            try await WorkService.shared.updateWork(
                id: effectiveWorkId,
                title: title, description: description, tags: tags,
                html: html, css: css, javascript: javascript,
                chatMessages: chatMessages, isPublished: isPublished,
                thumbnailUrl: finalThumbnailUrl, thumbnailAspectRatio: finalAspectRatio
            )
            
            isDirty = false
            lastSaved = Date()
        } catch {
            saveError = error
        }
    }
    
    func saveAndReset() async {
        if hasContent { await save() }
        reset()
    }
    
    // MARK: - Reset & Load
    
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
        thumbnailUrl = nil
        thumbnailAspectRatio = nil
        thumbnailImage = nil
        isDirty = false
        lastSaved = nil
        saveError = nil
        previewWebView = nil
    }
    
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
        thumbnailUrl = work.thumbnailUrl
        thumbnailAspectRatio = work.thumbnailAspectRatio
        thumbnailImage = nil
        isDirty = false
        lastSaved = work.updatedAt
    }
    
    func markDirty() {
        isDirty = true
    }
}
