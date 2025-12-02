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
    var selectedModel: AIModel = .deepseekV3Exp {
        didSet { AIService.shared.currentModel = selectedModel }
    }
    
    /// Reference to the work editor for tool execution
    weak var workEditor: WorkEditorViewModel?
    
    private var history: [[String: Any]] = []
    private var streamTask: Task<Void, Never>?
    
    // Debouncing for streaming updates
    private var pendingContent: String = ""
    private var pendingReasoning: String = ""
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: UInt64 = 50_000_000 // 50ms in nanoseconds
    
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
        syncToWorkEditor()
        
        streamTask = Task { await streamResponse() }
    }
    
    /// Retry the last failed request
    func retry() {
        // Remove the error message
        if let lastIndex = messages.indices.last, messages[lastIndex].role == .error {
            messages.removeLast()
        }
        
        // Restart streaming
        streamTask = Task { await streamResponse() }
    }
    
    /// Stop the current streaming response
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        
        // Finalize the last message if streaming
        if let lastIndex = messages.indices.last, messages[lastIndex].isStreaming {
            messages[lastIndex].isStreaming = false
            let content = messages[lastIndex].content
            if !content.isEmpty {
                history.append(["role": "assistant", "content": content])
                syncToWorkEditor()
            }
        }
        
        isLoading = false
    }
    
    func clear() {
        messages.removeAll()
        history.removeAll()
        history.append(["role": "system", "content": systemPrompt])
        syncToWorkEditor()
    }
    
    /// Load chat history from work editor (when editing existing work)
    func loadFromWorkEditor() {
        guard let editor = workEditor, !editor.chatMessages.isEmpty else { return }
        history = editor.chatMessages
        
        // Reconstruct messages for UI
        messages = []
        
        for msg in history {
            guard let role = msg["role"] as? String else { continue }
            
            switch role {
            case "user":
                if let content = msg["content"] as? String {
                    messages.append(ChatMessage(role: .user, content: content))
                }
                
            case "assistant":
                // Check for tool_calls (assistant message with function call)
                if let toolCalls = msg["tool_calls"] as? [[String: Any]],
                   let firstCall = toolCalls.first,
                   let function = firstCall["function"] as? [String: Any],
                   let name = function["name"] as? String,
                   let arguments = function["arguments"] as? String {
                    // Find the corresponding tool response for the result
                    let callId = firstCall["id"] as? String ?? ""
                    let result = findToolResult(for: callId)
                    
                    var message = ChatMessage(role: .assistant, content: "")
                    message.toolCall = ChatMessage.ToolCallInfo(name: name, arguments: arguments)
                    message.toolCall?.result = result
                    messages.append(message)
                }
                // Regular assistant message (may include reasoning)
                else if let content = msg["content"] as? String {
                    var message = ChatMessage(role: .assistant, content: content)
                    // Restore reasoning if present
                    if let reasoning = msg["reasoning_content"] as? String {
                        message.reasoning = reasoning
                    }
                    messages.append(message)
                }
                
            case "system", "tool":
                // Skip system prompts and tool responses (tool responses are merged into tool_calls)
                continue
                
            default:
                continue
            }
        }
    }
    
    /// Find tool result from history for a given call ID
    private func findToolResult(for callId: String) -> String? {
        for msg in history {
            if let role = msg["role"] as? String,
               role == "tool",
               let toolCallId = msg["tool_call_id"] as? String,
               toolCallId == callId,
               let content = msg["content"] as? String {
                return content
            }
        }
        return nil
    }
    
    /// Sync chat history to work editor for persistence
    private func syncToWorkEditor() {
        workEditor?.chatMessages = history
        workEditor?.markDirty()
    }
    
    // MARK: - Streaming
    
    private func streamResponse() async {
        isLoading = true
        pendingContent = ""
        pendingReasoning = ""
        
        let messageIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true, isThinking: true))
        
        do {
            for try await event in AIService.shared.streamChat(messages: history) {
                try Task.checkCancellation()
                
                switch event {
                case .reasoning(let text):
                    pendingReasoning += text
                    scheduleUIUpdate(at: messageIndex)
                    
                case .delta(let text):
                    // First content delta means thinking is done
                    if messages[messageIndex].isThinking {
                        messages[messageIndex].isThinking = false
                    }
                    pendingContent += text
                    scheduleUIUpdate(at: messageIndex)
                    
                case .toolCall(let id, let name, let arguments):
                    flushPendingContent(at: messageIndex)
                    await handleToolCall(id: id, name: name, arguments: arguments, at: messageIndex)
                    return
                }
            }
            
            flushPendingContent(at: messageIndex)
            finalizeMessage(at: messageIndex)
        } catch is CancellationError {
            flushPendingContent(at: messageIndex)
        } catch {
            messages.remove(at: messageIndex)
            messages.append(.error(friendlyErrorMessage(for: error)))
            isLoading = false
        }
    }
    
    /// Schedule a debounced UI update
    private func scheduleUIUpdate(at index: Int) {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceInterval)
                flushPendingContent(at: index)
            } catch {
                // Cancelled - content will be flushed elsewhere
            }
        }
    }
    
    /// Immediately apply pending content to the message
    private func flushPendingContent(at index: Int) {
        debounceTask?.cancel()
        debounceTask = nil
        
        guard index < messages.count else { return }
        
        if !pendingReasoning.isEmpty {
            messages[index].reasoning += pendingReasoning
            pendingReasoning = ""
        }
        
        if !pendingContent.isEmpty {
            messages[index].content += pendingContent
            pendingContent = ""
        }
    }
    
    private func friendlyErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.lowercased()
        
        if description.contains("timed out") || description.contains("timeout") {
            return "The request timed out. Please check your connection and try again."
        } else if description.contains("network") || description.contains("internet") {
            return "Network error. Please check your internet connection."
        } else if description.contains("unauthorized") || description.contains("401") {
            return "Authentication failed. Please sign in again."
        } else if description.contains("server") || description.contains("500") {
            return "Server error. Please try again later."
        } else {
            return "Something went wrong. Please try again."
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
        
        syncToWorkEditor()
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
        pendingContent = ""
        pendingReasoning = ""
        let messageIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true, isThinking: true))
        
        do {
            for try await event in AIService.shared.streamChat(messages: history) {
                try Task.checkCancellation()
                
                switch event {
                case .reasoning(let text):
                    pendingReasoning += text
                    scheduleUIUpdate(at: messageIndex)
                    
                case .delta(let text):
                    if messages[messageIndex].isThinking {
                        messages[messageIndex].isThinking = false
                    }
                    pendingContent += text
                    scheduleUIUpdate(at: messageIndex)
                    
                case .toolCall(let id, let name, let arguments):
                    flushPendingContent(at: messageIndex)
                    await handleToolCall(id: id, name: name, arguments: arguments, at: messageIndex)
                    return
                }
            }
            
            flushPendingContent(at: messageIndex)
            finalizeMessage(at: messageIndex)
        } catch is CancellationError {
            flushPendingContent(at: messageIndex)
        } catch {
            messages.remove(at: messageIndex)
            messages.append(.error(friendlyErrorMessage(for: error)))
            isLoading = false
        }
    }
    
    private func finalizeMessage(at index: Int) {
        messages[index].isStreaming = false
        messages[index].isThinking = false
        isLoading = false
        
        let message = messages[index]
        let content = message.content
        let reasoning = message.reasoning
        
        // Only save if there's content
        guard !content.isEmpty || !reasoning.isEmpty else { return }
        
        var historyEntry: [String: Any] = ["role": "assistant", "content": content]
        
        // Include reasoning if present
        if !reasoning.isEmpty {
            historyEntry["reasoning_content"] = reasoning
        }
        
        history.append(historyEntry)
        syncToWorkEditor()
    }
}
