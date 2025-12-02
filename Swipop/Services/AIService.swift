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
    
    // MARK: - Tool Execution (Client-side)
    
    func executeToolCall(name: String, arguments: String) -> String {
        switch name {
        case "get_weather":
            """
            {"location":"Beijing","temperature":22,"condition":"Sunny","humidity":45}
            """
        case "generate_code":
            """
            {"html":"<button class='glow-btn'>Click Me</button>","css":".glow-btn{padding:12px 24px;background:linear-gradient(135deg,#a855f7,#6366f1);color:#fff;border:none;border-radius:8px;cursor:pointer}"}
            """
        case "search_works":
            """
            {"results":[{"id":"1","title":"Neon Pulse","likes":567},{"id":"2","title":"Particle Storm","likes":890}],"total":2}
            """
        default:
            "{\"error\":\"Unknown tool\"}"
        }
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
    
    private static let tools: [[String: Any]] = [
        [
            "type": "function",
            "function": [
                "name": "get_weather",
                "description": "Get weather for a location",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": ["type": "string", "description": "City name"],
                        "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                    ],
                    "required": ["location"]
                ]
            ]
        ],
        [
            "type": "function",
            "function": [
                "name": "generate_code",
                "description": "Generate HTML/CSS/JS code",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "description": ["type": "string", "description": "What to generate"],
                        "type": ["type": "string", "enum": ["button", "card", "animation", "layout"]]
                    ],
                    "required": ["description", "type"]
                ]
            ]
        ],
        [
            "type": "function",
            "function": [
                "name": "search_works",
                "description": "Search creative works",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "query": ["type": "string", "description": "Search query"],
                        "limit": ["type": "integer", "description": "Max results"]
                    ],
                    "required": ["query"]
                ]
            ]
        ]
    ]
}
