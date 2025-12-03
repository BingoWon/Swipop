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
    var selectedModel: AIModel {
        get { AIModel(rawValue: selectedModelRaw) ?? .chat }
        set {
            selectedModelRaw = newValue.rawValue
            AIService.shared.currentModel = newValue
        }
    }
    
    @ObservationIgnored
    @AppStorage("selectedAIModel") private var selectedModelRaw: String = AIModel.chat.rawValue
    
    weak var workEditor: WorkEditorViewModel?
    
    private var history: [[String: Any]] = []
    private var streamTask: Task<Void, Never>?
    
    private var currentMessageIndex: Int = 0
    private var currentThinkingIndex: Int? = nil
    private var accumulatedReasoning: String = ""
    private var streamingToolCalls: [Int: (id: String, name: String, segmentIndex: Int)] = [:]
    
    private var pendingContent: String = ""
    private var pendingReasoning: String = ""
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: UInt64 = 50_000_000
    
    // MARK: - System Prompt
    
    private let systemPrompt = """
    You are a creative AI assistant in Swipop, a social app for sharing HTML/CSS/JS creative works.
    Help users create interactive, visually appealing web components.
    
    ## Available Tools
    
    ### Reading (always read before editing if unsure of current state)
    - read_html, read_css, read_javascript: Get current file content
    - read_metadata: Get current title, description, tags
    
    ### Writing (full replacement, for new files or complete rewrites)
    - write_html, write_css, write_javascript: Replace entire file content
    
    ### Replacing (targeted edits, preferred for existing files)
    - replace_in_html, replace_in_css, replace_in_javascript: Find and replace specific text
      - The 'search' text must match exactly and be unique in the file
      - Use for small, localized changes
    
    ### Metadata
    - update_metadata: Update title, description, and/or tags (only provide fields you want to change)
    
    ## Guidelines
    1. Use read_* first if you're unsure of the current content
    2. Prefer replace_in_* for small changes to existing code
    3. Use write_* for new files or major rewrites
    4. Make it visually impressive with modern CSS
    5. Add smooth animations and consider mobile responsiveness
    """
    
    // MARK: - Init
    
    init(workEditor: WorkEditorViewModel? = nil) {
        self.workEditor = workEditor
        history.append(["role": "system", "content": systemPrompt])
        AIService.shared.currentModel = selectedModel
    }
    
    // MARK: - Actions
    
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        messages.append(.user(text))
        
        clearReasoningFromHistory()
        history.append(["role": "user", "content": text])
        syncToWorkEditor()
        
        streamTask = Task { await streamResponse() }
    }
    
    func retry() {
        if let lastIndex = messages.indices.last, messages[lastIndex].role == .error {
            messages.removeLast()
        }
        streamTask = Task { await streamResponse() }
    }
    
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        debounceTask?.cancel()
        debounceTask = nil
        
        if currentMessageIndex < messages.count {
            flushPendingContent()
            finalizeCurrentThinking()
            
            for (_, info) in streamingToolCalls {
                if info.segmentIndex < messages[currentMessageIndex].segments.count,
                   case .toolCall(var segment) = messages[currentMessageIndex].segments[info.segmentIndex] {
                    segment.isStreaming = false
                    messages[currentMessageIndex].segments[info.segmentIndex] = .toolCall(segment)
                }
            }
            streamingToolCalls = [:]
            messages[currentMessageIndex].isStreaming = false
        }
        
        isLoading = false
    }
    
    func clear() {
        messages.removeAll()
        history.removeAll()
        history.append(["role": "system", "content": systemPrompt])
        pendingContent = ""
        pendingReasoning = ""
        accumulatedReasoning = ""
        streamingToolCalls = [:]
        currentThinkingIndex = nil
        syncToWorkEditor()
    }
    
    private func clearReasoningFromHistory() {
        for i in history.indices {
            if history[i]["reasoning_content"] != nil {
                history[i].removeValue(forKey: "reasoning_content")
            }
        }
    }
    
    // MARK: - Load from Work Editor
    
    func loadFromWorkEditor() {
        guard let editor = workEditor, !editor.chatMessages.isEmpty else { return }
        history = editor.chatMessages
        
        messages = []
        var currentAssistantMsg: ChatMessage?
        
        for (index, msg) in history.enumerated() {
            guard let role = msg["role"] as? String else { continue }
            
            switch role {
            case "user":
                if let assistantMsg = currentAssistantMsg, !assistantMsg.segments.isEmpty {
                    messages.append(assistantMsg)
                    currentAssistantMsg = nil
                }
                if let content = msg["content"] as? String {
                    messages.append(.user(content))
                }
                
            case "assistant":
                if currentAssistantMsg == nil {
                    currentAssistantMsg = ChatMessage(role: .assistant)
                }
                
                if let reasoning = msg["reasoning_content"] as? String, !reasoning.isEmpty {
                    var thinking = ChatMessage.ThinkingSegment()
                    thinking.text = reasoning
                    thinking.isActive = false
                    currentAssistantMsg?.segments.append(.thinking(thinking))
                }
                
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
                
                if let content = msg["content"] as? String, !content.isEmpty {
                    currentAssistantMsg?.segments.append(.content(content))
                }
                
            default:
                continue
            }
        }
        
        if let assistantMsg = currentAssistantMsg, !assistantMsg.segments.isEmpty {
            messages.append(assistantMsg)
        }
    }
    
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
        accumulatedReasoning = ""
        streamingToolCalls = [:]
        currentThinkingIndex = nil
        
        currentMessageIndex = messages.count
        var newMessage = ChatMessage(role: .assistant)
        newMessage.isStreaming = true
        
        if selectedModel.supportsThinking {
            var thinking = ChatMessage.ThinkingSegment()
            thinking.startTime = Date()
            thinking.isActive = true
            newMessage.segments.append(.thinking(thinking))
            currentThinkingIndex = 0
        }
        
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
                    accumulatedReasoning += text
                    scheduleUIUpdate()
                    
                case .content(let text):
                    finalizeCurrentThinking()
                    pendingContent += text
                    scheduleUIUpdate()
                    
                case .toolCallStart(let index, let id, let name):
                    flushPendingContent()
                    finalizeCurrentThinking()
                    
                    let segment = ChatMessage.ToolCallSegment(callId: id, name: name, arguments: "", isStreaming: true)
                    let segmentIndex = messages[currentMessageIndex].segments.count
                    messages[currentMessageIndex].segments.append(.toolCall(segment))
                    streamingToolCalls[index] = (id: id, name: name, segmentIndex: segmentIndex)
                    
                case .toolCallArguments(let index, let delta):
                    if let info = streamingToolCalls[index],
                       info.segmentIndex < messages[currentMessageIndex].segments.count,
                       case .toolCall(var segment) = messages[currentMessageIndex].segments[info.segmentIndex] {
                        segment.arguments += delta
                        messages[currentMessageIndex].segments[info.segmentIndex] = .toolCall(segment)
                    }
                    
                case .toolCallComplete(let index, let arguments):
                    if let info = streamingToolCalls[index],
                       info.segmentIndex < messages[currentMessageIndex].segments.count,
                       case .toolCall(var segment) = messages[currentMessageIndex].segments[info.segmentIndex] {
                        segment.arguments = arguments
                        segment.isStreaming = false
                        segment.result = executeToolCall(name: info.name, arguments: arguments)
                        messages[currentMessageIndex].segments[info.segmentIndex] = .toolCall(segment)
                    }
                }
            }
            
            if !streamingToolCalls.isEmpty {
                await finalizeToolCallsAndContinue()
            } else {
                flushPendingContent()
                finalizeCurrentMessage()
            }
        } catch is CancellationError {
            flushPendingContent()
        } catch {
            handleStreamError(error)
        }
    }
    
    private func handleStreamError(_ error: Error) {
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
    
    private func scheduleUIUpdate() {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceInterval)
                flushPendingContent()
            } catch {}
        }
    }
    
    private func flushPendingContent() {
        debounceTask?.cancel()
        debounceTask = nil
        
        guard currentMessageIndex < messages.count else { return }
        
        if !pendingReasoning.isEmpty {
            if let thinkingIdx = currentThinkingIndex,
               thinkingIdx < messages[currentMessageIndex].segments.count,
               case .thinking(var info) = messages[currentMessageIndex].segments[thinkingIdx] {
                info.text += pendingReasoning
                messages[currentMessageIndex].segments[thinkingIdx] = .thinking(info)
            }
            pendingReasoning = ""
        }
        
        if !pendingContent.isEmpty {
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
              case .thinking(var info) = messages[currentMessageIndex].segments[thinkingIdx] else { return }
        
        if info.isActive {
            info.isActive = false
            info.endTime = Date()
            
            if info.text.isEmpty {
                messages[currentMessageIndex].segments.remove(at: thinkingIdx)
                for (index, var callInfo) in streamingToolCalls {
                    if callInfo.segmentIndex > thinkingIdx {
                        callInfo.segmentIndex -= 1
                        streamingToolCalls[index] = callInfo
                    }
                }
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
            return "Request timed out. Please check your connection."
        } else if description.contains("network") || description.contains("internet") {
            return "Network error. Please check your connection."
        } else if description.contains("unauthorized") || description.contains("401") {
            return "Please sign in again."
        } else if description.contains("server") || description.contains("500") {
            return "Server error. Please try again."
        } else {
            return "Something went wrong. Please try again."
        }
    }
    
    // MARK: - Tool Handling
    
    private func finalizeToolCallsAndContinue() async {
        var assistantEntry: [String: Any] = ["role": "assistant"]
        
        if !accumulatedReasoning.isEmpty {
            assistantEntry["reasoning_content"] = accumulatedReasoning
        }
        
        assistantEntry["content"] = NSNull()
        
        var toolCallsArray: [[String: Any]] = []
        for index in streamingToolCalls.keys.sorted() {
            if let info = streamingToolCalls[index],
               info.segmentIndex < messages[currentMessageIndex].segments.count,
               case .toolCall(let segment) = messages[currentMessageIndex].segments[info.segmentIndex] {
                toolCallsArray.append([
                    "id": segment.callId,
                    "type": "function",
                    "function": ["name": segment.name, "arguments": segment.arguments]
                ])
            }
        }
        assistantEntry["tool_calls"] = toolCallsArray
        history.append(assistantEntry)
        
        for index in streamingToolCalls.keys.sorted() {
            if let info = streamingToolCalls[index],
               info.segmentIndex < messages[currentMessageIndex].segments.count,
               case .toolCall(let segment) = messages[currentMessageIndex].segments[info.segmentIndex],
               let result = segment.result {
                history.append(["role": "tool", "tool_call_id": segment.callId, "content": result])
            }
        }
        
        syncToWorkEditor()
        streamingToolCalls = [:]
        await continueAfterToolCalls()
    }
    
    private func continueAfterToolCalls() async {
        pendingContent = ""
        pendingReasoning = ""
        accumulatedReasoning = ""
        
        if selectedModel.supportsThinking {
            var thinking = ChatMessage.ThinkingSegment()
            thinking.startTime = Date()
            thinking.isActive = true
            let newThinkingIdx = messages[currentMessageIndex].segments.count
            messages[currentMessageIndex].segments.append(.thinking(thinking))
            currentThinkingIndex = newThinkingIdx
        }
        
        await processStream()
    }
    
    // MARK: - Tool Execution
    
    private enum CodeType { case html, css, javascript }
    
    private func executeToolCall(name: String, arguments: String) -> String {
        guard let tool = AIService.ToolName(rawValue: name) else {
            return #"{"error": "Unknown tool: \#(name)"}"#
        }
        
        let args: [String: Any]
        if arguments.isEmpty {
            args = [:]
        } else {
            guard let data = arguments.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return #"{"error": "Invalid arguments"}"#
            }
            args = parsed
        }
        
        switch tool {
        case .readMetadata:
            return executeReadMetadata()
        case .updateMetadata:
            return executeUpdateMetadata(args)
        // Read
        case .readHtml:
            return executeRead(.html)
        case .readCss:
            return executeRead(.css)
        case .readJavascript:
            return executeRead(.javascript)
        // Write
        case .writeHtml:
            return executeWrite(args, type: .html)
        case .writeCss:
            return executeWrite(args, type: .css)
        case .writeJavascript:
            return executeWrite(args, type: .javascript)
        // Replace
        case .replaceInHtml:
            return executeReplace(args, type: .html)
        case .replaceInCss:
            return executeReplace(args, type: .css)
        case .replaceInJavascript:
            return executeReplace(args, type: .javascript)
        }
    }
    
    private func executeRead(_ type: CodeType) -> String {
        guard let editor = workEditor else {
            return #"{"error": "Work editor not available"}"#
        }
        
        let content: String
        let typeName: String
        switch type {
        case .html:
            content = editor.html
            typeName = "HTML"
        case .css:
            content = editor.css
            typeName = "CSS"
        case .javascript:
            content = editor.javascript
            typeName = "JavaScript"
        }
        
        if content.isEmpty {
            return #"{"type": "\#(typeName)", "content": "", "lines": 0, "empty": true}"#
        }
        return #"{"type": "\#(typeName)", "content": \#(escapeJSON(content)), "lines": \#(content.components(separatedBy: .newlines).count)}"#
    }
    
    private func executeWrite(_ args: [String: Any], type: CodeType) -> String {
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
        return #"{"success": true, "type": "\#(typeName)", "lines": \#(content.components(separatedBy: .newlines).count)}"#
    }
    
    private func executeReplace(_ args: [String: Any], type: CodeType) -> String {
        guard let editor = workEditor else {
            return #"{"error": "Work editor not available"}"#
        }
        
        guard let search = args["search"] as? String else {
            return #"{"error": "Missing search parameter"}"#
        }
        guard let replace = args["replace"] as? String else {
            return #"{"error": "Missing replace parameter"}"#
        }
        
        var content: String
        let typeName: String
        switch type {
        case .html:
            content = editor.html
            typeName = "HTML"
        case .css:
            content = editor.css
            typeName = "CSS"
        case .javascript:
            content = editor.javascript
            typeName = "JavaScript"
        }
        
        // Check for matches
        let occurrences = content.components(separatedBy: search).count - 1
        if occurrences == 0 {
            return #"{"error": "Search text not found in \#(typeName)"}"#
        }
        if occurrences > 1 {
            return #"{"error": "Search text found \#(occurrences) times. Must be unique. Provide more context."}"#
        }
        
        // Perform replacement
        content = content.replacingOccurrences(of: search, with: replace)
        
        switch type {
        case .html: editor.html = content
        case .css: editor.css = content
        case .javascript: editor.javascript = content
        }
        
        editor.isDirty = true
        return #"{"success": true, "type": "\#(typeName)", "replaced": 1}"#
    }
    
    private func executeReadMetadata() -> String {
        guard let editor = workEditor else {
            return #"{"error": "Work editor not available"}"#
        }
        
        let tagsJSON = "[" + editor.tags.map { #""\#($0)""# }.joined(separator: ",") + "]"
        return #"{"title": \#(escapeJSON(editor.title)), "description": \#(escapeJSON(editor.description)), "tags": \#(tagsJSON)}"#
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
            return #"{"success": false, "error": "No fields provided"}"#
        }
        
        editor.isDirty = true
        return #"{"success": true, "updated": [\#(updated.map { #""\#($0)""# }.joined(separator: ","))]}"#
    }
    
    private func escapeJSON(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }
    
    private func finalizeCurrentMessage() {
        guard currentMessageIndex < messages.count else { return }
        
        messages[currentMessageIndex].isStreaming = false
        finalizeCurrentThinking()
        isLoading = false
        
        var allReasoning = ""
        var finalContent = ""
        
        for segment in messages[currentMessageIndex].segments {
            switch segment {
            case .thinking(let info):
                if !info.text.isEmpty { allReasoning += info.text }
            case .content(let text):
                finalContent += text
            case .toolCall:
                break
            }
        }
        
        if !finalContent.isEmpty || !allReasoning.isEmpty {
            var entry: [String: Any] = ["role": "assistant", "content": finalContent]
            if !allReasoning.isEmpty {
                entry["reasoning_content"] = allReasoning
            }
            history.append(entry)
            syncToWorkEditor()
        }
    }
}
