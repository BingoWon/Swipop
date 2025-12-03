//
//  WorkPreviewView.swift
//  Swipop
//
//  Live preview of work using WKWebView
//

import SwiftUI
import WebKit

struct WorkPreviewView: View {
    @Bindable var workEditor: WorkEditorViewModel
    
    private var isEmpty: Bool {
        workEditor.html.isEmpty && workEditor.css.isEmpty && workEditor.javascript.isEmpty
    }
    
    /// Content hash for change detection
    private var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(workEditor.html)
        hasher.combine(workEditor.css)
        hasher.combine(workEditor.javascript)
        return hasher.finalize()
    }
    
    var body: some View {
        if isEmpty {
            emptyState
        } else {
            PreviewWebView(
                html: workEditor.html,
                css: workEditor.css,
                javascript: workEditor.javascript,
                onWebViewReady: { webView in
                    workEditor.previewWebView = webView
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
    }
}

// MARK: - WebView (uses shared WorkRenderer)

private struct PreviewWebView: UIViewRepresentable {
    let html: String
    let css: String
    let javascript: String
    let onWebViewReady: (WKWebView) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
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
        
        let renderedHTML = WorkRenderer.render(html: html, css: css, javascript: javascript)
        webView.loadHTMLString(renderedHTML, baseURL: nil)
        
        // Notify parent after a short delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onWebViewReady(webView)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Handled by .id() modifier - view is recreated on content change
    }
}

#Preview {
    WorkPreviewView(workEditor: WorkEditorViewModel())
}
