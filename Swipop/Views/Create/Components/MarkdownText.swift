//
//  MarkdownText.swift
//  Swipop
//
//  Renders Markdown content with proper styling for chat messages
//

import SwiftUI

struct MarkdownText: View {
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if content.isEmpty {
            Text("...")
                .foregroundStyle(.secondary)
        } else {
            Text(attributedContent)
                .textSelection(.enabled)
        }
    }
    
    private var attributedContent: AttributedString {
        // Try to parse as Markdown, fallback to plain text
        do {
            var attributed = try AttributedString(markdown: content, options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))
            
            // Apply base styling
            attributed.foregroundColor = colorScheme == .dark ? .white : .black
            attributed.font = .system(size: 15)
            
            // Style inline code
            for run in attributed.runs {
                if run.inlinePresentationIntent?.contains(.code) == true {
                    let range = run.range
                    attributed[range].font = .system(size: 14, design: .monospaced)
                    attributed[range].backgroundColor = colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
                }
            }
            
            return attributed
        } catch {
            // Fallback to plain text
            var plain = AttributedString(content)
            plain.foregroundColor = colorScheme == .dark ? .white : .black
            plain.font = .system(size: 15)
            return plain
        }
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label
            if let language, !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondaryBackground.opacity(0.5))
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.9))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color.secondaryBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Rich Message Content

struct RichMessageContent: View {
    let content: String
    
    var body: some View {
        let blocks = parseContentBlocks(content)
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    MarkdownText(content: text)
                case .code(let code, let language):
                    CodeBlockView(code: code, language: language)
                }
            }
        }
    }
    
    // MARK: - Parsing
    
    private enum ContentBlock {
        case text(String)
        case code(String, language: String?)
    }
    
    private func parseContentBlocks(_ content: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var remaining = content
        
        // Regex to match code blocks: ```language\ncode\n```
        let codeBlockPattern = #"```(\w*)\n?([\s\S]*?)```"#
        
        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern) else {
            return [.text(content)]
        }
        
        var lastEnd = 0
        let nsString = remaining as NSString
        
        regex.enumerateMatches(in: remaining, range: NSRange(location: 0, length: nsString.length)) { match, _, _ in
            guard let match else { return }
            
            // Text before code block
            if match.range.location > lastEnd {
                let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let text = nsString.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    blocks.append(.text(text))
                }
            }
            
            // Code block
            let language = match.range(at: 1).location != NSNotFound
                ? nsString.substring(with: match.range(at: 1))
                : nil
            let code = match.range(at: 2).location != NSNotFound
                ? nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            
            if !code.isEmpty {
                blocks.append(.code(code, language: language?.isEmpty == true ? nil : language))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Remaining text after last code block
        if lastEnd < nsString.length {
            let text = nsString.substring(from: lastEnd).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(.text(text))
            }
        }
        
        // If no blocks found, return the whole content as text
        if blocks.isEmpty {
            blocks.append(.text(content))
        }
        
        return blocks
    }
}
