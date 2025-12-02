//
//  WorkPreviewView.swift
//  Swipop
//
//  Live preview of work using WKWebView
//

import SwiftUI
import WebKit

struct WorkPreviewView: View {
    let html: String
    let css: String
    let javascript: String
    
    private var fullHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    min-height: 100vh;
                    background: #0a0a0f;
                    color: white;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                \(css)
            </style>
        </head>
        <body>
            \(html)
            <script>\(javascript)</script>
        </body>
        </html>
        """
    }
    
    private var isEmpty: Bool {
        html.isEmpty && css.isEmpty && javascript.isEmpty
    }
    
    var body: some View {
        if isEmpty {
            emptyState
        } else {
            WebViewRepresentable(html: fullHTML)
                .ignoresSafeArea()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.slash")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No preview available")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Start chatting to generate code")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

// MARK: - WebView Wrapper

private struct WebViewRepresentable: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    WorkPreviewView(
        html: "<h1>Hello World</h1><p>This is a preview</p>",
        css: "h1 { color: #a855f7; } p { color: #888; }",
        javascript: ""
    )
}

