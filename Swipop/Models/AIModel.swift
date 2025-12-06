//
//  AIModel.swift
//  Swipop

import Foundation

/// Available DeepSeek AI models
enum AIModel: String, CaseIterable, Identifiable {
    /// DeepSeek V3.2 - Fast, efficient, no thinking
    case chat = "deepseek-chat"

    /// DeepSeek V3.2 Thinking - With reasoning/thinking capability
    case reasoner = "deepseek-reasoner"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chat: "DeepSeek V3.2"
        case .reasoner: "DeepSeek V3.2 Thinking"
        }
    }

    var description: String {
        switch self {
        case .chat: "Fast responses, great for simple tasks"
        case .reasoner: "Deep thinking, best for complex creations"
        }
    }

    /// Whether this model supports thinking/reasoning
    var supportsThinking: Bool {
        self == .reasoner
    }
}
