//
//  WorkRenderer.swift
//  Swipop
//

import Foundation

enum WorkRenderer {
    
    /// Render from Work model (for Feed)
    static func render(_ work: Work) -> String {
        render(
            title: work.title,
            html: work.htmlContent ?? "",
            css: work.cssContent ?? "",
            javascript: work.jsContent ?? ""
        )
    }
    
    /// Render from raw content (for Preview)
    static func render(title: String = "", html: String, css: String, javascript: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <title>\(escapeHTML(title))</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    width: 100%; 
                    height: 100dvh;
                    overflow: hidden;
                    background: #000;
                    color: #fff;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
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
    
    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
