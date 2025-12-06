//
//  ProjectEditorViewModel.swift
//  Swipop
//
//  Shared state for project creation/editing
//

import SwiftUI
import WebKit

@MainActor
@Observable
final class ProjectEditorViewModel {
    // MARK: - Default Templates

    static let defaultHTML = """
    <div class="container">
      <h1>Hello, World!</h1>
      <p>Start creating your masterpiece</p>
    </div>
    """

    static let defaultCSS = """
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #1a1a2e, #16213e);
      font-family: system-ui, -apple-system, sans-serif;
    }

    .container {
      text-align: center;
      color: white;
    }

    h1 {
      font-size: 2.5rem;
      margin-bottom: 0.5rem;
    }

    p {
      opacity: 0.7;
    }
    """

    static let defaultJS = """
    // Add interactivity here
    // Example: document.querySelector('h1').addEventListener('click', () => { ... })
    """

    // MARK: - Identity

    var projectId: UUID?

    // MARK: - Content

    var html = defaultHTML { didSet { if html != oldValue { isDirty = true } } }
    var css = defaultCSS { didSet { if css != oldValue { isDirty = true } } }
    var javascript = defaultJS { didSet { if javascript != oldValue { isDirty = true } } }

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
    var isNew: Bool { projectId == nil }
    var hasThumbnail: Bool { thumbnailUrl != nil || thumbnailImage != nil }

    /// Small thumbnail URL for settings preview (200px)
    var smallThumbnailURL: URL? { ThumbnailTransform.url(from: thumbnailUrl, size: .small) }

    // MARK: - Thumbnail Actions

    func captureThumbnail(aspectRatio: ThumbnailAspectRatio) async {
        guard let webView = previewWebView else { return }

        isCapturingThumbnail = true
        defer { isCapturingThumbnail = false }

        do {
            let cropped = try await ThumbnailService.shared.capture(from: webView, aspectRatio: aspectRatio)
            thumbnailImage = cropped
            thumbnailAspectRatio = cropped.size.width / cropped.size.height
            isDirty = true
        } catch {
            saveError = error
        }
    }

    func setThumbnail(image: UIImage, aspectRatio: ThumbnailAspectRatio) {
        let cropped = ThumbnailService.cropToRatio(image, targetRatio: aspectRatio.ratio)
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
            // Create project if new
            let effectiveProjectId: UUID
            if let existingId = projectId {
                effectiveProjectId = existingId
            } else {
                effectiveProjectId = try await ProjectService.shared.createProject(
                    title: title, description: description, tags: tags,
                    html: html, css: css, javascript: javascript,
                    chatMessages: chatMessages, isPublished: isPublished,
                    thumbnailUrl: nil, thumbnailAspectRatio: nil
                )
                projectId = effectiveProjectId
            }

            // Upload thumbnail if needed
            var finalThumbnailUrl = thumbnailUrl
            var finalAspectRatio = thumbnailAspectRatio

            if let image = thumbnailImage {
                let result = try await ThumbnailService.shared.upload(image: image, projectId: effectiveProjectId)
                finalThumbnailUrl = result.url
                finalAspectRatio = result.aspectRatio
                thumbnailUrl = result.url
                thumbnailAspectRatio = result.aspectRatio
                thumbnailImage = nil
            }

            // Update project
            try await ProjectService.shared.updateProject(
                id: effectiveProjectId,
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
        if hasContent, isDirty { await save() }
        reset()
    }

    // MARK: - Reset & Load

    func reset() {
        projectId = nil
        html = Self.defaultHTML
        css = Self.defaultCSS
        javascript = Self.defaultJS
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

    func load(project: Project) {
        projectId = project.id
        title = project.title
        description = project.description ?? ""
        tags = project.tags ?? []
        html = project.htmlContent ?? ""
        css = project.cssContent ?? ""
        javascript = project.jsContent ?? ""
        chatMessages = project.chatMessages ?? []
        isPublished = project.isPublished
        thumbnailUrl = project.thumbnailUrl
        thumbnailAspectRatio = project.thumbnailAspectRatio
        thumbnailImage = nil
        isDirty = false
        lastSaved = project.updatedAt
    }

    func markDirty() {
        isDirty = true
    }
}
