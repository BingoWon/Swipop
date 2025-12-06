//
//  Color+Theme.swift
//  Swipop
//
//  Adaptive colors for Light/Dark mode
//

import SwiftUI

extension Color {
    // MARK: - Brand (same in both modes)

    static let brand = Color(hex: "a855f7")
    static let brandSecondary = Color(hex: "6366f1")

    // MARK: - Adaptive Backgrounds

    /// Primary background (Light: white, Dark: near-black)
    static let appBackground = Color(light: Color(hex: "f8f8fc"), dark: Color(hex: "0a0a0f"))

    /// Secondary background (Light: light gray, Dark: dark gray)
    static let secondaryBackground = Color(light: Color(hex: "f0f0f5"), dark: Color(hex: "1a1a2e"))

    /// Tertiary background for cards/sheets
    static let tertiaryBackground = Color(light: Color(hex: "ffffff"), dark: Color(hex: "16162a"))

    /// Sheet/modal background
    static let sheetBackground = Color(light: Color(hex: "ffffff"), dark: Color(hex: "1a1a2e"))

    // MARK: - Adaptive Text

    /// Primary text color
    static let textPrimary = Color(light: Color(hex: "1a1a1a"), dark: .white)

    /// Secondary text color
    static let textSecondary = Color(light: Color(hex: "666666"), dark: .white.opacity(0.6))

    /// Tertiary text color
    static let textTertiary = Color(light: Color(hex: "999999"), dark: .white.opacity(0.4))

    // MARK: - Chat Bubbles

    /// User message bubble
    static let userBubble = Color(hex: "3b82f6")

    /// Assistant message bubble
    static let assistantBubble = Color(light: Color(hex: "f0f0f5"), dark: .white.opacity(0.1))

    // MARK: - Borders & Dividers

    static let border = Color(light: Color(hex: "e5e5e5"), dark: .white.opacity(0.1))
    static let divider = Color(light: Color(hex: "e0e0e0"), dark: .white.opacity(0.08))
}

// MARK: - Adaptive Color Initializer

extension Color {
    /// Create a color that adapts to Light/Dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Gradients

extension ShapeStyle where Self == LinearGradient {
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [.brand, .brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var appBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.appBackground, .secondaryBackground, .appBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
