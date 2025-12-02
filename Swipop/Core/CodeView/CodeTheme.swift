//
//  CodeTheme.swift
//  Swipop
//
//  Shared GitHub Dark theme for Runestone code views
//

import SwiftUI
import Runestone

final class CodeTheme: Runestone.Theme {
    
    // MARK: - Configuration
    
    private let fontSize: CGFloat
    
    init(fontSize: CGFloat = 14) {
        self.fontSize = fontSize
    }
    
    // MARK: - Fonts
    
    var font: UIFont { .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    var lineNumberFont: UIFont { .monospacedSystemFont(ofSize: fontSize - 2, weight: .regular) }
    
    // MARK: - Colors
    
    let textColor = UIColor(Color(hex: "e6edf3"))
    let gutterBackgroundColor = UIColor(Color(hex: "0d1117"))
    let gutterHairlineColor = UIColor(Color(hex: "30363d"))
    let lineNumberColor = UIColor(Color(hex: "6e7681"))
    let selectedLineBackgroundColor = UIColor(Color(hex: "161b22"))
    let selectedLinesLineNumberColor = UIColor(Color(hex: "e6edf3"))
    let selectedLinesGutterBackgroundColor = UIColor(Color(hex: "161b22"))
    let invisibleCharactersColor = UIColor(Color(hex: "484f58"))
    let pageGuideHairlineColor = UIColor(Color(hex: "30363d"))
    let pageGuideBackgroundColor = UIColor(Color(hex: "161b22"))
    let markedTextBackgroundColor = UIColor(Color(hex: "388bfd").opacity(0.3))
    
    // MARK: - Syntax Highlighting
    
    func textColor(for highlightName: String) -> UIColor? {
        switch highlightName {
        case "keyword", "keyword.control", "keyword.function", "keyword.operator":
            return UIColor(Color(hex: "ff7b72"))
        case "string", "string.special", "escape":
            return UIColor(Color(hex: "a5d6ff"))
        case "comment", "comment.block", "comment.line":
            return UIColor(Color(hex: "8b949e"))
        case "function", "function.method", "method":
            return UIColor(Color(hex: "d2a8ff"))
        case "type", "type.builtin", "class", "constructor":
            return UIColor(Color(hex: "ffa657"))
        case "variable", "variable.builtin", "property", "attribute", "attribute.builtin":
            return UIColor(Color(hex: "79c0ff"))
        case "constant", "constant.builtin", "number", "boolean":
            return UIColor(Color(hex: "79c0ff"))
        case "tag", "tag.builtin":
            return UIColor(Color(hex: "7ee787"))
        case "operator", "punctuation", "punctuation.bracket", "punctuation.delimiter":
            return UIColor(Color(hex: "e6edf3"))
        default:
            return nil
        }
    }
    
    func fontTraits(for highlightName: String) -> FontTraits {
        switch highlightName {
        case "keyword", "keyword.control":
            return .bold
        case "comment", "comment.block", "comment.line":
            return .italic
        default:
            return []
        }
    }
}

