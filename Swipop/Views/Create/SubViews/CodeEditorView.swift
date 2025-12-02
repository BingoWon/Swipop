//
//  CodeEditorView.swift
//  Swipop
//
//  Code editor view with syntax highlighting for HTML/CSS/JS
//

import SwiftUI
import Runestone
import TreeSitterHTMLRunestone
import TreeSitterCSSRunestone
import TreeSitterJavaScriptRunestone

struct CodeEditorView: View {
    let language: CodeLanguage
    @Binding var code: String
    
    var body: some View {
        ZStack {
            if code.isEmpty {
                emptyState
            } else {
                EditableCodeView(code: $code, language: language)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color(hex: "0d1117"))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: language.emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(language.color.opacity(0.5))
            
            Text("No \(language.rawValue) code yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Chat with AI to generate code")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

// MARK: - Language Extensions

private extension CodeLanguage {
    var emptyIcon: String {
        switch self {
        case .html: "doc.text"
        case .css: "paintbrush"
        case .javascript: "bolt"
        }
    }
    
    var color: Color {
        switch self {
        case .html: .orange
        case .css: .blue
        case .javascript: .yellow
        }
    }
}

// MARK: - Editable Code View

private struct EditableCodeView: UIViewRepresentable {
    @Binding var code: String
    let language: CodeLanguage
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.backgroundColor = UIColor(Color(hex: "0d1117"))
        textView.isEditable = true
        textView.isSelectable = true
        textView.showLineNumbers = true
        textView.lineHeightMultiplier = 1.3
        textView.kern = 0.3
        textView.gutterLeadingPadding = 12
        textView.gutterTrailingPadding = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 12)
        textView.theme = EditorTheme()
        textView.editorDelegate = context.coordinator
        
        // Disable character pairs for simplicity
        textView.characterPairs = []
        
        return textView
    }
    
    func updateUIView(_ textView: TextView, context: Context) {
        // Only update if content changed externally
        if textView.text != code {
            let state = TextViewState(
                text: code,
                theme: EditorTheme(),
                language: language.language
            )
            textView.setState(state)
        }
    }
    
    class Coordinator: NSObject, TextViewDelegate {
        var parent: EditableCodeView
        
        init(_ parent: EditableCodeView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: TextView) {
            parent.code = textView.text
        }
    }
}

// MARK: - Editor Theme (GitHub Dark)

private final class EditorTheme: Runestone.Theme {
    let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
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
        case "keyword", "keyword.control", "keyword.function", "keyword.operator":
            return UIColor(Color(hex: "ff7b72"))
        case "string", "string.special":
            return UIColor(Color(hex: "a5d6ff"))
        case "comment", "comment.block", "comment.line":
            return UIColor(Color(hex: "8b949e"))
        case "function", "function.method", "method":
            return UIColor(Color(hex: "d2a8ff"))
        case "type", "type.builtin", "class", "constructor":
            return UIColor(Color(hex: "ffa657"))
        case "variable", "variable.builtin", "property":
            return UIColor(Color(hex: "79c0ff"))
        case "constant", "constant.builtin", "number", "boolean":
            return UIColor(Color(hex: "79c0ff"))
        case "operator", "punctuation", "punctuation.bracket", "punctuation.delimiter":
            return UIColor(Color(hex: "e6edf3"))
        case "tag", "tag.builtin":
            return UIColor(Color(hex: "7ee787"))
        case "attribute", "attribute.builtin":
            return UIColor(Color(hex: "79c0ff"))
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

#Preview {
    CodeEditorView(
        language: .html,
        code: .constant("<h1>Hello World</h1>")
    )
}

