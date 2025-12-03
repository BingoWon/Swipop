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
                    
                    // Enable thinking for reasoner model
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
                    
                    // Parse SSE stream
                    // Track multiple tool calls by index
                    var pendingToolCalls: [Int: (id: String, name: String, arguments: String)] = [:]
                    
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
                        
                        // Tool calls (may have multiple, distinguished by index)
                        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                let index = tc["index"] as? Int ?? 0
                                
                                if let id = tc["id"] as? String {
                                    // New tool call starting
                                    pendingToolCalls[index] = (id: id, name: "", arguments: "")
                                }
                                
                                if let function = tc["function"] as? [String: Any] {
                                    if let name = function["name"] as? String {
                                        pendingToolCalls[index]?.name = name
                                    }
                                    if let args = function["arguments"] as? String {
                                        pendingToolCalls[index]?.arguments += args
                                    }
                                }
                            }
                        }
                        
                        // Check finish reason
                        if let finishReason = choice["finish_reason"] as? String {
                            if finishReason == "tool_calls" {
                                // Yield all pending tool calls in order
                                for index in pendingToolCalls.keys.sorted() {
                                    if let call = pendingToolCalls[index], !call.name.isEmpty {
                                        continuation.yield(.toolCall(id: call.id, name: call.name, arguments: call.arguments))
                                    }
                                }
                                pendingToolCalls.removeAll()
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
        case toolCall(id: String, name: String, arguments: String)
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
