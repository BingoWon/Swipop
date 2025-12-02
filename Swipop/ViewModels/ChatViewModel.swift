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
    Help users create components, find inspiration, and answer web development questions.
    
    You have tools to:
    - update_metadata: Set or change the work's title, description, and tags
    
    Use tools when appropriate. Be creative, helpful, and concise.
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
        }
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
