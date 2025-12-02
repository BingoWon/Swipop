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
    
    var icon: String {
        switch self {
        case .html: "doc.text"
        case .css: "paintbrush"
        case .javascript: "bolt"
        }
    }
}

// MARK: - Runestone Code View

struct RunestoneCodeView: View {
    let language: CodeLanguage
    @Binding var code: String
    let isEditable: Bool
    
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
        ZStack {
            if code.isEmpty && isEditable {
                emptyState
            } else {
                CodeTextView(code: $code, language: language, isEditable: isEditable)
            }
        }
        .background(Color(hex: "0d1117"))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: language.icon)
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

// MARK: - Code Text View (UIViewRepresentable)

private struct CodeTextView: UIViewRepresentable {
    @Binding var code: String
    let language: CodeLanguage
    let isEditable: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.backgroundColor = UIColor(Color(hex: "0d1117"))
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.showLineNumbers = true
        textView.lineHeightMultiplier = 1.3
        textView.kern = 0.3
        textView.characterPairs = []
        textView.gutterLeadingPadding = 12
        textView.gutterTrailingPadding = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 12)
        textView.theme = CodeTheme()
        
        if isEditable {
            textView.editorDelegate = context.coordinator
        }
        
        return textView
    }
    
    func updateUIView(_ textView: TextView, context: Context) {
        guard textView.text != code else { return }
        
        let state = TextViewState(
            text: code,
            theme: CodeTheme(),
            language: language.treeSitterLanguage
        )
        textView.setState(state)
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
