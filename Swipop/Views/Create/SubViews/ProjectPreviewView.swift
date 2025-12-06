//
//  ProjectPreviewView.swift
//  Swipop
//
//  Live preview of project using WKWebView
//

import SwiftUI
import WebKit

struct ProjectPreviewView: View {
    @Bindable var projectEditor: ProjectEditorViewModel

    private var isEmpty: Bool {
        projectEditor.html.isEmpty && projectEditor.css.isEmpty && projectEditor.javascript.isEmpty
    }

    /// Content hash for change detection
    private var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(projectEditor.html)
        hasher.combine(projectEditor.css)
        hasher.combine(projectEditor.javascript)
        return hasher.finalize()
    }

    var body: some View {
        if isEmpty {
            emptyState
        } else {
            PreviewWebView(
                html: projectEditor.html,
                css: projectEditor.css,
                javascript: projectEditor.javascript,
                onWebViewReady: { webView in
                    projectEditor.previewWebView = webView
                }
            )
            .id(contentHash)
            .ignoresSafeArea()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No preview available")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Start chatting to generate code")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WebView (uses shared ProjectRenderer)

private struct PreviewWebView: UIViewRepresentable {
    let html: String
    let css: String
    let javascript: String
    let onWebViewReady: (WKWebView) -> Void

    func makeUIView(context _: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false

        let renderedHTML = ProjectRenderer.render(html: html, css: css, javascript: javascript)
        webView.loadHTMLString(renderedHTML, baseURL: nil)

        // Notify parent after a short delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onWebViewReady(webView)
        }

        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {
        // Handled by .id() modifier - view is recreated on content change
    }
}

#Preview {
    ProjectPreviewView(projectEditor: ProjectEditorViewModel())
}
