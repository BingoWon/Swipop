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
    
    private var history: [[String: Any]] = []
    
    // MARK: - System Prompt
    
    private let systemPrompt = """
    You are a creative AI assistant in Swipop, a social app for sharing HTML/CSS/JS creative works.
    Help users create components, find inspiration, and answer web development questions.
    Use tools when appropriate. Be creative, helpful, and concise.
    """
    
    // MARK: - Init
    
    init() {
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
        
        let result = AIService.shared.executeToolCall(name: name, arguments: arguments)
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
