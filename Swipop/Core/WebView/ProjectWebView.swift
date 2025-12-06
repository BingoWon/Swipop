//
//  ProjectWebView.swift
//  Swipop
//
//  SwiftUI wrapper for WKWebView to render projects (full screen)
//

import SwiftUI
import WebKit

struct ProjectWebView: UIViewRepresentable {
    let project: Project
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

    func updateUIView(_ webView: WKWebView, context _: Context) {
        let html = ProjectRenderer.render(project)
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

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            onError?(error)
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            onError?(error)
        }
    }
}
