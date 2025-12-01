//
//  WebViewPool.swift
//  Swipop
//
//  Reusable WebView pool for performance optimization
//

import WebKit

final class WebViewPool {
    
    // MARK: - Singleton
    
    static let shared = WebViewPool()
    
    // MARK: - Properties
    
    private var pool: [WKWebView] = []
    private let maxSize = 3
    private let lock = NSLock()
    
    private init() {
        // Pre-warm pool
        Task { @MainActor in
            for _ in 0..<maxSize {
                pool.append(createWebView())
            }
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func acquire() -> WKWebView {
        lock.lock()
        defer { lock.unlock() }
        
        if let webView = pool.popLast() {
            return webView
        }
        
        return createWebView()
    }
    
    @MainActor
    func release(_ webView: WKWebView) {
        lock.lock()
        defer { lock.unlock() }
        
        // Clear content
        webView.loadHTMLString("", baseURL: nil)
        
        if pool.count < maxSize {
            pool.append(webView)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Optimize for performance
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        
        return webView
    }
}

