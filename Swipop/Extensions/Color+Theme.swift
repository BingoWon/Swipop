//
//  Color+Theme.swift
//  Swipop
//

import SwiftUI

extension Color {
    // MARK: - Brand
    
    static let brand = Color(hex: "a855f7")
    static let brandSecondary = Color(hex: "6366f1")
    
    // MARK: - Backgrounds
    
    static let darkBackground = Color(hex: "0a0a0f")
    static let darkBackgroundSecondary = Color(hex: "0f0f1a")
    static let darkSheet = Color(hex: "1a1a2e")
    
    // MARK: - Bubbles
    
    static let userBubble = Color(hex: "3b82f6")
    static let assistantBubble = Color.white.opacity(0.1)
}

extension ShapeStyle where Self == LinearGradient {
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [.brand, .brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var darkBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.darkBackground, .darkBackgroundSecondary, .darkBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
