//
//  ChatViewModel.swift
//  Swipop
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    
    // MARK: - State
    
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var error: Error?
    var selectedModel: AIModel = .deepseekV3Exp {
        didSet { AIService.shared.currentModel = selectedModel }
    }
    
    /// Reference to the work editor for tool execution
    weak var workEditor: WorkEditorViewModel?
    
    private var history: [[String: Any]] = []
    
    // MARK: - System Prompt
    
    private let systemPrompt = """
    You are a creative AI assistant in Swipop, a social app for sharing HTML/CSS/JS creative works.
    Help users create interactive, visually appealing web components.
    
    You have tools to:
    - edit_html: Set the HTML content (body content only, no html/head/body tags)
    - edit_css: Set the CSS styles (animations, layouts, effects)
    - edit_javascript: Set the JavaScript code (interactivity, logic)
    - update_metadata: Set title, description, and tags
    
    When creating works:
    1. Use modern CSS (flexbox, grid, custom properties, animations)
    2. Write clean, semantic HTML
    3. Use ES6+ JavaScript
    4. Make it visually impressive - users share these as creative works
    5. Add smooth animations and transitions
    6. Consider mobile responsiveness
    
    Be creative and make things that look amazing!
    """
    
    // MARK: - Init
    
    init(workEditor: WorkEditorViewModel? = nil) {
        self.workEditor = workEditor
        history.append(["role": "system", "content": systemPrompt])
    }
    
    // MARK: - Actions
    
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))
        history.append(["role": "user", "content": text])
        
        Task { await streamResponse() }
    }
    
    func clear() {
        messages.removeAll()
        history.removeAll()
        error = nil
        history.append(["role": "system", "content": systemPrompt])
    }
    
    // MARK: - Streaming
    
    private func streamResponse() async {
        isLoading = true
        error = nil
        
        let messageIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true))
        
        do {
            for try await event in AIService.shared.streamChat(messages: history) {
                switch event {
                case .delta(let text):
                    messages[messageIndex].content += text
                    
                case .toolCall(let id, let name, let arguments):
                    await handleToolCall(id: id, name: name, arguments: arguments, at: messageIndex)
                    return
                }
            }
            
            finalizeMessage(at: messageIndex)
        } catch {
            messages[messageIndex].content = "Error: \(error.localizedDescription)"
            messages[messageIndex].isStreaming = false
            self.error = error
            isLoading = false
        }
    }
    
    private func handleToolCall(id: String, name: String, arguments: String, at index: Int) async {
        messages[index].toolCall = ChatMessage.ToolCallInfo(name: name, arguments: arguments)
        
        // Execute tool and get result
        let result = executeToolCall(name: name, arguments: arguments)
        messages[index].toolCall?.result = result
        
        // Add tool call to history
        history.append([
            "role": "assistant",
            "content": NSNull(),
            "tool_calls": [[
                "id": id,
                "type": "function",
                "function": ["name": name, "arguments": arguments]
            ]]
        ])
        
        // Add tool result to history
        history.append([
            "role": "tool",
            "tool_call_id": id,
            "content": result
        ])
        
        await continueAfterToolCall()
    }
    
    // MARK: - Tool Execution
    
    private func executeToolCall(name: String, arguments: String) -> String {
        guard let tool = AIService.ToolName(rawValue: name) else {
            return #"{"error": "Unknown tool: \#(name)"}"#
        }
        
        guard let data = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return #"{"error": "Invalid arguments"}"#
        }
        
        switch tool {
        case .updateMetadata:
            return executeUpdateMetadata(args)
        case .editHtml:
            return executeEditCode(args, type: .html)
        case .editCss:
            return executeEditCode(args, type: .css)
        case .editJavascript:
            return executeEditCode(args, type: .javascript)
        }
    }
    
    private enum CodeType { case html, css, javascript }
    
    private func executeEditCode(_ args: [String: Any], type: CodeType) -> String {
        guard let editor = workEditor else {
            return #"{"error": "Work editor not available"}"#
        }
        
        guard let content = args["content"] as? String else {
            return #"{"error": "Missing content parameter"}"#
        }
        
        let typeName: String
        switch type {
        case .html:
            editor.html = content
            typeName = "HTML"
        case .css:
            editor.css = content
            typeName = "CSS"
        case .javascript:
            editor.javascript = content
            typeName = "JavaScript"
        }
        
        editor.isDirty = true
        
        let charCount = content.count
        let lineCount = content.components(separatedBy: .newlines).count
        return #"{"success": true, "type": "\#(typeName)", "stats": {"characters": \#(charCount), "lines": \#(lineCount)}}"#
    }
    
    private func executeUpdateMetadata(_ args: [String: Any]) -> String {
        guard let editor = workEditor else {
            return #"{"error": "Work editor not available"}"#
        }
        
        var updated: [String] = []
        
        if let title = args["title"] as? String {
            editor.title = title
            updated.append("title")
        }
        
        if let description = args["description"] as? String {
            editor.description = description
            updated.append("description")
        }
        
        if let tags = args["tags"] as? [String] {
            editor.tags = tags
            updated.append("tags")
        }
        
        if updated.isEmpty {
            return #"{"success": false, "message": "No fields to update"}"#
        }
        
        editor.isDirty = true
        
        // Build response
        let updatedJson = updated.map { #""\#($0)""# }.joined(separator: ", ")
        return #"{"success": true, "updated": [\#(updatedJson)], "current": {"title": "\#(editor.title)", "description": "\#(editor.description)", "tags": \#(tagsToJson(editor.tags))}}"#
    }
    
    private func tagsToJson(_ tags: [String]) -> String {
        let escaped = tags.map { #""\#($0)""# }.joined(separator: ", ")
        return "[\(escaped)]"
    }
    
    private func continueAfterToolCall() async {
        let messageIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true))
        
        do {
            for try await event in AIService.shared.streamChat(messages: history) {
                switch event {
                case .delta(let text):
                    messages[messageIndex].content += text
                    
                case .toolCall(let id, let name, let arguments):
                    await handleToolCall(id: id, name: name, arguments: arguments, at: messageIndex)
                    return
                }
            }
            
            finalizeMessage(at: messageIndex)
        } catch {
            messages[messageIndex].content = "Error: \(error.localizedDescription)"
            messages[messageIndex].isStreaming = false
            self.error = error
            isLoading = false
        }
    }
    
    private func finalizeMessage(at index: Int) {
        messages[index].isStreaming = false
        isLoading = false
        
        let content = messages[index].content
        if !content.isEmpty {
            history.append(["role": "assistant", "content": content])
        }
    }
}
