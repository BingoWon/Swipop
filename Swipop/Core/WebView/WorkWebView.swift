//
//  WorkWebView.swift
//  Swipop
//
//  SwiftUI wrapper for WKWebView to render works (full screen)
//

import SwiftUI
import WebKit

struct WorkWebView: UIViewRepresentable {
    
    let work: Work
    var onError: ((Error) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Allow content to extend into safe areas
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        
        // Disable scrolling bounces for immersive feel
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = WorkRenderer.render(work)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onError: onError)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let onError: ((Error) -> Void)?
        
        init(onError: ((Error) -> Void)?) {
            self.onError = onError
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onError?(error)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onError?(error)
        }
    }
}
