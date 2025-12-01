//
//  WorkRenderer.swift
//  Swipop
//
//  Assembles HTML/CSS/JS into a complete document
//

import Foundation

enum WorkRenderer {
    
    /// Renders a Work into a complete HTML document
    /// Full viewport with no safe area restrictions
    static func render(_ work: Work) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <title>\(escapeHTML(work.title))</title>
            <style>
                * { 
                    margin: 0; 
                    padding: 0; 
                    box-sizing: border-box; 
                }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    min-height: 100vh;
                    min-height: 100dvh;
                    overflow: hidden;
                    background: #000;
                    color: #fff;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    -webkit-overflow-scrolling: touch;
                }
                /* Support for safe area insets - content extends edge to edge */
                body {
                    padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
                    padding: 0; /* Override to go truly full screen */
                }
                \(work.cssContent ?? "")
            </style>
        </head>
        <body>
            \(work.htmlContent ?? "")
            <script>
                \(work.jsContent ?? "")
            </script>
        </body>
        </html>
        """
    }
    
    /// Escapes HTML special characters
    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
