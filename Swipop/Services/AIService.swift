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
                    
                    // Track tool calls - only store arguments, yield start immediately
                    var toolCallArguments: [Int: String] = [:]
                    var toolCallStarted: Set<Int> = []
                    
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                        
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let choice = choices.first,
                              let delta = choice["delta"] as? [String: Any] else { continue }
                        
                        // Reasoning content (thinking)
                        if let reasoning = delta["reasoning_content"] as? String, !reasoning.isEmpty {
                            continuation.yield(.reasoning(reasoning))
                        }
                        
                        // Content delta
                        if let content = delta["content"] as? String, !content.isEmpty {
                            continuation.yield(.content(content))
                        }
                        
                        // Tool calls - yield start immediately when we get id+name
                        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                let index = tc["index"] as? Int ?? 0
                                
                                // Initialize arguments storage
                                if toolCallArguments[index] == nil {
                                    toolCallArguments[index] = ""
                                }
                                
                                // Check for tool call start (id and name)
                                if let id = tc["id"] as? String,
                                   let function = tc["function"] as? [String: Any],
                                   let name = function["name"] as? String,
                                   !toolCallStarted.contains(index) {
                                    // Yield start immediately
                                    toolCallStarted.insert(index)
                                    continuation.yield(.toolCallStart(index: index, id: id, name: name))
                                }
                                
                                // Accumulate arguments
                                if let function = tc["function"] as? [String: Any],
                                   let args = function["arguments"] as? String {
                                    toolCallArguments[index]! += args
                                    // Yield argument delta for UI updates
                                    continuation.yield(.toolCallArguments(index: index, delta: args))
                                }
                            }
                        }
                        
                        // Check finish reason
                        if let finishReason = choice["finish_reason"] as? String {
                            if finishReason == "tool_calls" {
                                // Yield complete with full arguments
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
    }
    
    enum ToolName: String {
        case updateMetadata = "update_metadata"
        case editHtml = "edit_html"
        case editCss = "edit_css"
        case editJavascript = "edit_javascript"
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
    
    // MARK: - Tools Definition
    
    static let tools: [[String: Any]] = [
        [
            "type": "function",
            "function": [
                "name": "update_metadata",
                "description": "Update the work's metadata (title, description, tags). Use when user wants to name or describe their work.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "title": ["type": "string", "description": "Work title, concise and descriptive"],
                        "description": ["type": "string", "description": "Brief description of what the work does"],
                        "tags": ["type": "array", "items": ["type": "string"], "description": "Tags for discovery (lowercase, no #)"]
                    ]
                ]
            ]
        ],
        [
            "type": "function",
            "function": [
                "name": "edit_html",
                "description": "Replace the entire HTML content. Use for structure and content. Do NOT include <html>, <head>, or <body> tags.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete HTML content"]
                    ],
                    "required": ["content"]
                ]
            ]
        ],
        [
            "type": "function",
            "function": [
                "name": "edit_css",
                "description": "Replace the entire CSS content. Use for styling, animations, and visual effects.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete CSS content"]
                    ],
                    "required": ["content"]
                ]
            ]
        ],
        [
            "type": "function",
            "function": [
                "name": "edit_javascript",
                "description": "Replace the entire JavaScript content. Use for interactivity and dynamic behavior.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete JavaScript content"]
                    ],
                    "required": ["content"]
                ]
            ]
        ]
    ]
}
