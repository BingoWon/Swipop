//
//  AIService.swift
//  Swipop

import Foundation
import Supabase

@MainActor
final class AIService {
    static let shared = AIService()
    
    var currentModel: AIModel = .reasoner
    
    private let edgeFunctionURL: URL
    
    private init() {
        edgeFunctionURL = Secrets.supabaseURL.appendingPathComponent("functions/v1/ai-chat")
    }
    
    // MARK: - Streaming Chat
    
    func streamChat(messages: [[String: Any]]) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let session = try? await SupabaseService.shared.client.auth.session else {
                        throw AIError.unauthorized
                    }
                    
                    var request = URLRequest(url: edgeFunctionURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var body: [String: Any] = [
                        "model": currentModel.rawValue,
                        "messages": messages,
                        "tools": Self.tools
                    ]
                    
                    if currentModel.supportsThinking {
                        body["thinking"] = ["type": "enabled"]
                    }
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw AIError.invalidResponse
                    }
                    
                    if httpResponse.statusCode != 200 {
                        throw AIError.serverError(httpResponse.statusCode)
                    }
                    
                    var toolCallArguments: [Int: String] = [:]
                    var toolCallStarted: Set<Int> = []
                    
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                        
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                        
                        // Parse usage (appears in last chunk)
                        if let usage = json["usage"] as? [String: Any] {
                            let promptTokens = usage["prompt_tokens"] as? Int ?? 0
                            let completionTokens = usage["completion_tokens"] as? Int ?? 0
                            var reasoningTokens = 0
                            if let details = usage["completion_tokens_details"] as? [String: Any] {
                                reasoningTokens = details["reasoning_tokens"] as? Int ?? 0
                            }
                            continuation.yield(.usage(promptTokens: promptTokens, completionTokens: completionTokens, reasoningTokens: reasoningTokens))
                        }
                        
                        guard let choices = json["choices"] as? [[String: Any]],
                              let choice = choices.first,
                              let delta = choice["delta"] as? [String: Any] else { continue }
                        
                        if let reasoning = delta["reasoning_content"] as? String, !reasoning.isEmpty {
                            continuation.yield(.reasoning(reasoning))
                        }
                        
                        if let content = delta["content"] as? String, !content.isEmpty {
                            continuation.yield(.content(content))
                        }
                        
                        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                let index = tc["index"] as? Int ?? 0
                                
                                if toolCallArguments[index] == nil {
                                    toolCallArguments[index] = ""
                                }
                                
                                if let id = tc["id"] as? String,
                                   let function = tc["function"] as? [String: Any],
                                   let name = function["name"] as? String,
                                   !toolCallStarted.contains(index) {
                                    toolCallStarted.insert(index)
                                    continuation.yield(.toolCallStart(index: index, id: id, name: name))
                                }
                                
                                if let function = tc["function"] as? [String: Any],
                                   let args = function["arguments"] as? String {
                                    toolCallArguments[index]! += args
                                    continuation.yield(.toolCallArguments(index: index, delta: args))
                                }
                            }
                        }
                        
                        if let finishReason = choice["finish_reason"] as? String {
                            if finishReason == "tool_calls" {
                                for index in toolCallArguments.keys.sorted() {
                                    let args = toolCallArguments[index] ?? ""
                                    continuation.yield(.toolCallComplete(index: index, arguments: args))
                                }
                                toolCallArguments.removeAll()
                                toolCallStarted.removeAll()
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Types
    
    enum StreamEvent {
        case reasoning(String)
        case content(String)
        case toolCallStart(index: Int, id: String, name: String)
        case toolCallArguments(index: Int, delta: String)
        case toolCallComplete(index: Int, arguments: String)
        case usage(promptTokens: Int, completionTokens: Int, reasoningTokens: Int)
    }
    
    enum ToolName: String {
        case updateMetadata = "update_metadata"
        case writeHtml = "write_html"
        case writeCss = "write_css"
        case writeJavascript = "write_javascript"
        case replaceInHtml = "replace_in_html"
        case replaceInCss = "replace_in_css"
        case replaceInJavascript = "replace_in_javascript"
        case summarizeConversation = "summarize_conversation"
    }
    
    enum AIError: LocalizedError {
        case unauthorized
        case invalidResponse
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .unauthorized: "Please sign in to use AI"
            case .invalidResponse: "Invalid server response"
            case .serverError(let code): "Server error: \(code)"
            }
        }
    }
    
    // MARK: - Tools Definition (8 tools)
    
    static let tools: [[String: Any]] = [
        // Metadata
        tool("update_metadata",
             "Update work metadata. Only provide fields you want to change.",
             properties: [
                "title": prop("string", "Work title"),
                "description": prop("string", "Brief description"),
                "tags": ["type": "array", "items": ["type": "string"], "description": "Tags for discovery"]
             ]),
        
        // Write (full replacement)
        tool("write_html",
             "Replace entire HTML content. Use for new works or complete rewrites. Do NOT include <html>, <head>, or <body> tags.",
             properties: ["content": prop("string", "Complete HTML content")],
             required: ["content"]),
        tool("write_css",
             "Replace entire CSS content. Use for new works or complete rewrites.",
             properties: ["content": prop("string", "Complete CSS content")],
             required: ["content"]),
        tool("write_javascript",
             "Replace entire JavaScript content. Use for new works or complete rewrites.",
             properties: ["content": prop("string", "Complete JavaScript content")],
             required: ["content"]),
        
        // Replace (targeted edits)
        tool("replace_in_html",
             "Make targeted edits to HTML. The search text must match exactly and be unique.",
             properties: [
                "search": prop("string", "Exact text to find (must be unique)"),
                "replace": prop("string", "New text to substitute")
             ],
             required: ["search", "replace"]),
        tool("replace_in_css",
             "Make targeted edits to CSS. The search text must match exactly and be unique.",
             properties: [
                "search": prop("string", "Exact text to find (must be unique)"),
                "replace": prop("string", "New text to substitute")
             ],
             required: ["search", "replace"]),
        tool("replace_in_javascript",
             "Make targeted edits to JavaScript. The search text must match exactly and be unique.",
             properties: [
                "search": prop("string", "Exact text to find (must be unique)"),
                "replace": prop("string", "New text to substitute")
             ],
             required: ["search", "replace"]),
        
        // Context Management
        tool("summarize_conversation",
             "Create a summary when context window is nearly full. Only call when explicitly instructed.",
             properties: [
                "summary": prop("string", "Comprehensive summary including: user's goals, key decisions, completed tasks, current work progress, and user preferences")
             ],
             required: ["summary"]),
    ]
    
    // MARK: - Tool Builder Helpers
    
    private static func tool(_ name: String, _ description: String, properties: [String: Any], required: [String]? = nil) -> [String: Any] {
        var params: [String: Any] = ["type": "object", "properties": properties]
        if let required = required { params["required"] = required }
        return ["type": "function", "function": ["name": name, "description": description, "parameters": params]]
    }
    
    private static func prop(_ type: String, _ description: String) -> [String: String] {
        ["type": type, "description": description]
    }
}
