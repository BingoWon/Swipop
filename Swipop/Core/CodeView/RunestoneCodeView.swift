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
    
    var treeSitterLanguage: TreeSitterLanguage {
        switch self {
        case .html: .html
        case .css: .css
        case .javascript: .javaScript
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

// MARK: - Runestone Code View

struct RunestoneCodeView: View {
    let language: CodeLanguage
    @Binding var code: String
    let isEditable: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(language: CodeLanguage, code: Binding<String>, isEditable: Bool = false) {
        self.language = language
        self._code = code
        self.isEditable = isEditable
    }
    
    /// Read-only convenience initializer
    init(language: CodeLanguage, code: String) {
        self.language = language
        self._code = .constant(code)
        self.isEditable = false
    }
    
    var body: some View {
        CodeTextView(code: $code, language: language, isEditable: isEditable, colorScheme: colorScheme)
            .background(colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "f6f8fa"))
    }
}

// MARK: - Code Text View (UIViewRepresentable)

private struct CodeTextView: UIViewRepresentable {
    @Binding var code: String
    let language: CodeLanguage
    let isEditable: Bool
    let colorScheme: ColorScheme
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.backgroundColor = colorScheme == .dark ? UIColor(Color(hex: "0d1117")) : UIColor(Color(hex: "f6f8fa"))
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.showLineNumbers = true
        textView.lineHeightMultiplier = 1.3
        textView.kern = 0.3
        textView.characterPairs = []
        // Minimal gutter for maximum code space
        textView.gutterLeadingPadding = 0
        textView.gutterTrailingPadding = 6
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 2)
        textView.theme = CodeTheme(colorScheme: colorScheme)
        
        // Use automatic adjustment like WebView - scrolls under safe areas
        textView.contentInsetAdjustmentBehavior = .scrollableAxes
        
        if isEditable {
            textView.editorDelegate = context.coordinator
        }
        
        return textView
    }
    
    func updateUIView(_ textView: TextView, context: Context) {
        // Update theme if color scheme changed
        let newTheme = CodeTheme(colorScheme: colorScheme)
        textView.backgroundColor = colorScheme == .dark ? UIColor(Color(hex: "0d1117")) : UIColor(Color(hex: "f6f8fa"))
        
        if textView.text != code {
            let state = TextViewState(
                text: code,
                theme: newTheme,
                language: language.treeSitterLanguage
            )
            textView.setState(state)
        } else {
            textView.theme = newTheme
        }
    }
    
    class Coordinator: NSObject, TextViewDelegate {
        var parent: CodeTextView
        
        init(_ parent: CodeTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: TextView) {
            parent.code = textView.text
        }
    }
}

// MARK: - Preview

#Preview("Read-only") {
    RunestoneCodeView(
        language: .html,
        code: """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Hello World</title>
        </head>
        <body>
            <h1 class="title">Hello, Swipop!</h1>
        </body>
        </html>
        """
    )
    .frame(height: 300)
}

#Preview("Editable") {
    RunestoneCodeView(
        language: .css,
        code: .constant("h1 { color: red; }"),
        isEditable: true
    )
    .frame(height: 300)
}
