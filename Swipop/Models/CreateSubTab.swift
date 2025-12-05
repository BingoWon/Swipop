//
//  CreateSubTab.swift
//  Swipop
//

import SwiftUI

enum CreateSubTab: String, CaseIterable, Identifiable {
    case chat
    case preview
    case html
    case css
    case javascript
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chat: "bubble.left.fill"
        case .preview: "play.fill"
        case .html: "chevron.left.forwardslash.chevron.right"
        case .css: "paintbrush.fill"
        case .javascript: "bolt.fill"
        }
    }
    
    var title: String {
        switch self {
        case .chat: "Chat"
        case .preview: "Preview"
        case .html: "HTML"
        case .css: "CSS"
        case .javascript: "JS"
        }
    }
    
    var color: Color {
        switch self {
        case .chat: .brand
        case .preview: .green
        case .html: .orange
        case .css: .blue
        case .javascript: .yellow
        }
    }
    
    var isCodeTab: Bool {
        switch self {
        case .html, .css, .javascript: true
        case .chat, .preview: false
        }
    }
}

