//
//  AIService.swift
//  Swipop
//

import Foundation
import Supabase

@MainActor
final class AIService {
    static let shared = AIService()
    
    var currentModel: AIModel = .deepseekV3Exp
    
    private let supabase = SupabaseService.shared.client
    private let edgeFunctionURL: URL
    
    private init() {
        edgeFunctionURL = Secrets.supabaseURL.appendingPathComponent("functions/v1/ai-chat")
    }
    
    // MARK: - Streaming Chat
    
    func streamChat(messages: [[String: Any]]) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Get auth token
                    guard let session = try? await supabase.auth.session else {
                        throw AIError.unauthorized
                    }
                    let token = session.accessToken
                    
                    // Build request
                    var request = URLRequest(url: edgeFunctionURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let body: [String: Any] = [
                        "model": currentModel.rawValue,
                        "messages": messages,
                        "tools": Self.tools
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    // Stream SSE
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw AIError.invalidResponse
                    }
                    
                    if httpResponse.statusCode != 200 {
                        throw AIError.serverError(httpResponse.statusCode)
                    }
                    
                    // Parse SSE stream
                    var pendingToolCall: (id: String, name: String, arguments: String)?
                    
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                        
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let choice = choices.first,
                              let delta = choice["delta"] as? [String: Any] else { continue }
                        
                        // Content delta
                        if let content = delta["content"] as? String {
                            continuation.yield(.delta(content))
                        }
                        
                        // Tool calls
                        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                if let function = tc["function"] as? [String: Any] {
                                    if let name = function["name"] as? String {
                                        pendingToolCall = (tc["id"] as? String ?? "", name, "")
                                    }
                                    if let args = function["arguments"] as? String, var pending = pendingToolCall {
                                        pending.arguments += args
                                        pendingToolCall = pending
                                    }
                                }
                            }
                        }
                        
                        // Finish reason
                        if let finishReason = choice["finish_reason"] as? String,
                           finishReason == "tool_calls",
                           let call = pendingToolCall {
                            continuation.yield(.toolCall(id: call.id, name: call.name, arguments: call.arguments))
                            pendingToolCall = nil
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Tool Names
    
    enum ToolName: String {
        case updateMetadata = "update_metadata"
        case editHtml = "edit_html"
        case editCss = "edit_css"
        case editJavascript = "edit_javascript"
    }
    
    // MARK: - Types
    
    enum StreamEvent {
        case delta(String)
        case toolCall(id: String, name: String, arguments: String)
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
        // Metadata tool
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
        // HTML editor
        [
            "type": "function",
            "function": [
                "name": "edit_html",
                "description": "Replace the entire HTML content of the work. Use for creating or modifying the structure and content. Include semantic HTML elements. Do NOT include <html>, <head>, or <body> tags - only the content that goes inside body.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete HTML content to set"]
                    ],
                    "required": ["content"]
                ]
            ]
        ],
        // CSS editor
        [
            "type": "function",
            "function": [
                "name": "edit_css",
                "description": "Replace the entire CSS content of the work. Use for styling, animations, and visual effects. Include responsive design when appropriate. Write clean, modern CSS.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete CSS content to set"]
                    ],
                    "required": ["content"]
                ]
            ]
        ],
        // JavaScript editor
        [
            "type": "function",
            "function": [
                "name": "edit_javascript",
                "description": "Replace the entire JavaScript content of the work. Use for interactivity, animations, and dynamic behavior. Write clean ES6+ code. Avoid external dependencies unless via CDN.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "content": ["type": "string", "description": "The complete JavaScript content to set"]
                    ],
                    "required": ["content"]
                ]
            ]
        ]
    ]
}
