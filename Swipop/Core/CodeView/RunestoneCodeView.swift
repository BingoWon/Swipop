//
//  RunestoneCodeView.swift
//  Swipop
//
//  SwiftUI wrapper for Runestone TextView with Tree-sitter syntax highlighting
//

import SwiftUI
import Runestone
import TreeSitterHTMLRunestone
import TreeSitterCSSRunestone
import TreeSitterJavaScriptRunestone

// MARK: - Code Language

enum CodeLanguage: String, CaseIterable {
    case html = "HTML"
    case css = "CSS"
    case javascript = "JS"
    
    var language: TreeSitterLanguage {
        switch self {
        case .html: .html
        case .css: .css
        case .javascript: .javaScript
        }
    }
}

// MARK: - Runestone Code View

struct RunestoneCodeView: UIViewRepresentable {
    let code: String
    let language: CodeLanguage
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.backgroundColor = UIColor(Color(hex: "0d1117"))
        textView.isEditable = false
        textView.isSelectable = true
        textView.showLineNumbers = true
        textView.lineHeightMultiplier = 1.3
        textView.kern = 0.3
        textView.characterPairs = []
        textView.gutterLeadingPadding = 12
        textView.gutterTrailingPadding = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 12)
        
        // Apply theme
        textView.theme = CodeTheme()
        
        return textView
    }
    
    func updateUIView(_ textView: TextView, context: Context) {
        // Set language mode
        let state = TextViewState(
            text: code,
            theme: CodeTheme(),
            language: language.language
        )
        textView.setState(state)
    }
}

// MARK: - Code Theme (GitHub Dark Style)

private final class CodeTheme: Runestone.Theme {
    
    let font: UIFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    let textColor: UIColor = UIColor(Color(hex: "e6edf3"))
    
    let gutterBackgroundColor: UIColor = UIColor(Color(hex: "0d1117"))
    let gutterHairlineColor: UIColor = UIColor(Color(hex: "30363d"))
    
    let lineNumberColor: UIColor = UIColor(Color(hex: "6e7681"))
    let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    
    let selectedLineBackgroundColor: UIColor = UIColor(Color(hex: "161b22"))
    let selectedLinesLineNumberColor: UIColor = UIColor(Color(hex: "e6edf3"))
    let selectedLinesGutterBackgroundColor: UIColor = UIColor(Color(hex: "161b22"))
    
    let invisibleCharactersColor: UIColor = UIColor(Color(hex: "484f58"))
    
    let pageGuideHairlineColor: UIColor = UIColor(Color(hex: "30363d"))
    let pageGuideBackgroundColor: UIColor = UIColor(Color(hex: "161b22"))
    
    let markedTextBackgroundColor: UIColor = UIColor(Color(hex: "388bfd").opacity(0.3))
    
    func textColor(for highlightName: String) -> UIColor? {
        switch highlightName {
        // Keywords
        case "keyword", "keyword.control", "keyword.function", "keyword.operator":
            return UIColor(Color(hex: "ff7b72"))
            
        // Strings
        case "string", "string.special":
            return UIColor(Color(hex: "a5d6ff"))
            
        // Comments
        case "comment", "comment.block", "comment.line":
            return UIColor(Color(hex: "8b949e"))
            
        // Functions
        case "function", "function.method", "method":
            return UIColor(Color(hex: "d2a8ff"))
            
        // Types / Classes
        case "type", "type.builtin", "class", "constructor":
            return UIColor(Color(hex: "ffa657"))
            
        // Variables / Properties
        case "variable", "variable.builtin", "property":
            return UIColor(Color(hex: "79c0ff"))
            
        // Constants / Numbers
        case "constant", "constant.builtin", "number", "boolean":
            return UIColor(Color(hex: "79c0ff"))
            
        // Operators
        case "operator", "punctuation", "punctuation.bracket", "punctuation.delimiter":
            return UIColor(Color(hex: "e6edf3"))
            
        // Tags (HTML)
        case "tag", "tag.builtin":
            return UIColor(Color(hex: "7ee787"))
            
        // Attributes (HTML)
        case "attribute", "attribute.builtin":
            return UIColor(Color(hex: "79c0ff"))
            
        // Escape sequences
        case "escape":
            return UIColor(Color(hex: "a5d6ff"))
            
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

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        RunestoneCodeView(
            code: """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>Hello World</title>
            </head>
            <body>
                <h1 class="title">Hello, Swipop!</h1>
                <script>
                    console.log("Welcome!");
                </script>
            </body>
            </html>
            """,
            language: .html
        )
    }
    .frame(height: 300)
    .background(Color.black)
}
