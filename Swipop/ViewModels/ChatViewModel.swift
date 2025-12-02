//
//  ChatViewModel.swift
//  Swipop

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
    
    // Current streaming state
    private var currentMessageIndex: Int = 0
    private var currentThinkingIndex: Int? = nil
    
    // Debouncing for streaming updates
    private var pendingContent: String = ""
    private var pendingReasoning: String = ""
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: UInt64 = 50_000_000 // 50ms
    
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
        messages.append(.user(text))
        history.append(["role": "user", "content": text])
        syncToWorkEditor()
        
        streamTask = Task { await streamResponse() }
    }
    
    /// Retry the last failed request
    func retry() {
        if let lastIndex = messages.indices.last, messages[lastIndex].role == .error {
            messages.removeLast()
        }
        streamTask = Task { await streamResponse() }
    }
    
    /// Stop the current streaming response
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        
        if currentMessageIndex < messages.count {
            flushPendingContent()
            finalizeCurrentMessage()
        }
        
        isLoading = false
    }
    
    func clear() {
        messages.removeAll()
        history.removeAll()
        history.append(["role": "system", "content": systemPrompt])
        pendingContent = ""
        pendingReasoning = ""
        currentThinkingIndex = nil
        syncToWorkEditor()
    }
    
    /// Load chat history from work editor (when editing existing work)
    func loadFromWorkEditor() {
        guard let editor = workEditor, !editor.chatMessages.isEmpty else { return }
        history = editor.chatMessages
        
        messages = []
        var currentAssistantMsg: ChatMessage?
        
        for (index, msg) in history.enumerated() {
            guard let role = msg["role"] as? String else { continue }
            
            switch role {
            case "user":
                // Flush any pending assistant message
                if var assistantMsg = currentAssistantMsg {
                    messages.append(assistantMsg)
                    currentAssistantMsg = nil
                }
                
                if let content = msg["content"] as? String {
                    messages.append(.user(content))
                }
                
            case "assistant":
                // Start or continue assistant message
                if currentAssistantMsg == nil {
                    currentAssistantMsg = ChatMessage(role: .assistant)
                }
                
                // Add reasoning as thinking segment
                if let reasoning = msg["reasoning_content"] as? String, !reasoning.isEmpty {
                    var thinking = ChatMessage.ThinkingSegment()
                    thinking.text = reasoning
                    thinking.isActive = false
                    currentAssistantMsg?.segments.append(.thinking(thinking))
                }
                
                // Add tool calls
                if let toolCalls = msg["tool_calls"] as? [[String: Any]] {
                    for call in toolCalls {
                        if let function = call["function"] as? [String: Any],
                           let callId = call["id"] as? String,
                           let name = function["name"] as? String,
                           let arguments = function["arguments"] as? String {
                            var toolSegment = ChatMessage.ToolCallSegment(callId: callId, name: name, arguments: arguments)
                            toolSegment.result = findToolResult(for: callId, startingFrom: index)
                            currentAssistantMsg?.segments.append(.toolCall(toolSegment))
                        }
                    }
                }
                
                // Add content
                if let content = msg["content"] as? String, !content.isEmpty {
                    currentAssistantMsg?.segments.append(.content(content))
                }
                
            case "system", "tool":
                continue
                
            default:
                continue
            }
        }
        
        // Flush final assistant message
        if let assistantMsg = currentAssistantMsg, !assistantMsg.segments.isEmpty {
            messages.append(assistantMsg)
        }
    }
    
    /// Find tool result from history for a given call ID
    private func findToolResult(for callId: String, startingFrom index: Int) -> String? {
        for i in index..<history.count {
            let msg = history[i]
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
    
    private func syncToWorkEditor() {
        workEditor?.chatMessages = history
        workEditor?.markDirty()
    }
    
    // MARK: - Streaming
    
    private func streamResponse() async {
        isLoading = true
        pendingContent = ""
        pendingReasoning = ""
        currentThinkingIndex = nil
        
        // Create a new assistant message
        currentMessageIndex = messages.count
        var newMessage = ChatMessage(role: .assistant)
        newMessage.isStreaming = true
        
        // Start with an active thinking segment
        var thinking = ChatMessage.ThinkingSegment()
        thinking.startTime = Date()
        thinking.isActive = true
        newMessage.segments.append(.thinking(thinking))
        currentThinkingIndex = 0
        
        messages.append(newMessage)
        
        await processStream()
    }
    
    private func processStream() async {
        do {
            for try await event in AIService.shared.streamChat(messages: history) {
                try Task.checkCancellation()
                
                switch event {
                case .reasoning(let text):
                    pendingReasoning += text
                    scheduleUIUpdate()
                    
                case .delta(let text):
                    // First content delta means thinking is done
                    finalizeCurrentThinking()
                    pendingContent += text
                    scheduleUIUpdate()
                    
                case .toolCall(let id, let name, let arguments):
                    flushPendingContent()
                    finalizeCurrentThinking()
                    await handleToolCall(id: id, name: name, arguments: arguments)
                    return // Will continue in handleToolCall
                }
            }
            
            flushPendingContent()
            finalizeCurrentMessage()
        } catch is CancellationError {
            flushPendingContent()
        } catch {
            messages[currentMessageIndex].isStreaming = false
            messages[currentMessageIndex].segments.removeAll { segment in
                if case .thinking(let info) = segment { return info.text.isEmpty }
                return false
            }
            if messages[currentMessageIndex].segments.isEmpty {
                messages.remove(at: currentMessageIndex)
            }
            messages.append(.error(friendlyErrorMessage(for: error)))
            isLoading = false
        }
    }
    
    private func scheduleUIUpdate() {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceInterval)
                flushPendingContent()
            } catch {
                // Cancelled
            }
        }
    }
    
    private func flushPendingContent() {
        debounceTask?.cancel()
        debounceTask = nil
        
        guard currentMessageIndex < messages.count else { return }
        
        // Update thinking segment with pending reasoning
        if !pendingReasoning.isEmpty {
            if let thinkingIdx = currentThinkingIndex,
               thinkingIdx < messages[currentMessageIndex].segments.count,
               case .thinking(var info) = messages[currentMessageIndex].segments[thinkingIdx] {
                info.text += pendingReasoning
                messages[currentMessageIndex].segments[thinkingIdx] = .thinking(info)
            }
            pendingReasoning = ""
        }
        
        // Update content
        if !pendingContent.isEmpty {
            // Find or create content segment at end
            if let lastIdx = messages[currentMessageIndex].segments.indices.last,
               case .content(let existing) = messages[currentMessageIndex].segments[lastIdx] {
                messages[currentMessageIndex].segments[lastIdx] = .content(existing + pendingContent)
            } else {
                messages[currentMessageIndex].segments.append(.content(pendingContent))
            }
            pendingContent = ""
        }
    }
    
    private func finalizeCurrentThinking() {
        guard let thinkingIdx = currentThinkingIndex,
              currentMessageIndex < messages.count,
              thinkingIdx < messages[currentMessageIndex].segments.count,
              case .thinking(var info) = messages[currentMessageIndex].segments[thinkingIdx] else {
            return
        }
        
        if info.isActive {
            info.isActive = false
            info.endTime = Date()
            
            // Remove if empty
            if info.text.isEmpty {
                messages[currentMessageIndex].segments.remove(at: thinkingIdx)
                currentThinkingIndex = nil
            } else {
                messages[currentMessageIndex].segments[thinkingIdx] = .thinking(info)
                currentThinkingIndex = nil
            }
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
    
    // MARK: - Tool Handling
    
    private func handleToolCall(id: String, name: String, arguments: String) async {
        // Add tool call segment to current message
        var toolSegment = ChatMessage.ToolCallSegment(callId: id, name: name, arguments: arguments)
        let result = executeToolCall(name: name, arguments: arguments)
        toolSegment.result = result
        messages[currentMessageIndex].segments.append(.toolCall(toolSegment))
        
        // Add to history
        history.append([
            "role": "assistant",
            "content": NSNull(),
            "tool_calls": [[
                "id": id,
                "type": "function",
                "function": ["name": name, "arguments": arguments]
            ]]
        ])
        
        history.append([
            "role": "tool",
            "tool_call_id": id,
            "content": result
        ])
        
        syncToWorkEditor()
        
        // Continue streaming - may get more thinking, tool calls, or content
        await continueAfterToolCall()
    }
    
    private func continueAfterToolCall() async {
        pendingContent = ""
        pendingReasoning = ""
        
        // Start new thinking segment (may be filled or may be empty)
        var thinking = ChatMessage.ThinkingSegment()
        thinking.startTime = Date()
        thinking.isActive = true
        let newThinkingIdx = messages[currentMessageIndex].segments.count
        messages[currentMessageIndex].segments.append(.thinking(thinking))
        currentThinkingIndex = newThinkingIdx
        
        await processStream()
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
        
        let updatedJson = updated.map { #""\#($0)""# }.joined(separator: ", ")
        return #"{"success": true, "updated": [\#(updatedJson)], "current": {"title": "\#(editor.title)", "description": "\#(editor.description)", "tags": \#(tagsToJson(editor.tags))}}"#
    }
    
    private func tagsToJson(_ tags: [String]) -> String {
        let escaped = tags.map { #""\#($0)""# }.joined(separator: ", ")
        return "[\(escaped)]"
    }
    
    private func finalizeCurrentMessage() {
        guard currentMessageIndex < messages.count else { return }
        
        messages[currentMessageIndex].isStreaming = false
        finalizeCurrentThinking()
        isLoading = false
        
        // Build history entries for assistant content and reasoning
        var hasContent = false
        var allReasoning = ""
        var finalContent = ""
        
        for segment in messages[currentMessageIndex].segments {
            switch segment {
            case .thinking(let info):
                if !info.text.isEmpty {
                    allReasoning += info.text
                }
            case .content(let text):
                if !text.isEmpty {
                    finalContent += text
                    hasContent = true
                }
            case .toolCall:
                // Already added to history
                break
            }
        }
        
        // Only add final content to history (tool calls already added)
        if hasContent || !allReasoning.isEmpty {
            var entry: [String: Any] = ["role": "assistant", "content": finalContent]
            if !allReasoning.isEmpty {
                entry["reasoning_content"] = allReasoning
            }
            history.append(entry)
            syncToWorkEditor()
        }
    }
}
