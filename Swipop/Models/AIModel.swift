//
//  AIModel.swift
//  Swipop
//

import Foundation

/// Available AI models for chat
enum AIModel: String, CaseIterable, Identifiable {
    case deepseekV3Exp = "deepseek-ai/DeepSeek-V3.2-Exp"
    case deepseekV3Terminus = "deepseek-ai/DeepSeek-V3.1-Terminus"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .deepseekV3Exp: "DeepSeek V3.2 Exp"
        case .deepseekV3Terminus: "DeepSeek V3.1 Terminus"
        }
    }
    
    var description: String {
        switch self {
        case .deepseekV3Exp: "Latest experimental model"
        case .deepseekV3Terminus: "Stable production model"
        }
    }
}

