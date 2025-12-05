//
//  GlassModifiers.swift
//  Swipop
//
//  Unified glass effect modifiers for iOS 26 (Liquid Glass) and iOS 18 (Material)
//

import SwiftUI

// MARK: - Glass Background Modifier (for Floating Elements)

struct GlassBackgroundModifier: ViewModifier {
    var shape: GlassShape = .capsule
    
    enum GlassShape {
        case capsule, roundedRect(cornerRadius: CGFloat)
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.modifier(LiquidGlassBackground(shape: shape))
        } else {
            content.modifier(MaterialGlassBackground(shape: shape))
        }
    }
}

@available(iOS 26.0, *)
private struct LiquidGlassBackground: ViewModifier {
    let shape: GlassBackgroundModifier.GlassShape
    
    func body(content: Content) -> some View {
        switch shape {
        case .capsule:
            content.background(Capsule().fill(.clear).glassEffect())
        case .roundedRect(let radius):
            content.background(RoundedRectangle(cornerRadius: radius).fill(.clear).glassEffect())
        }
    }
}

private struct MaterialGlassBackground: ViewModifier {
    let shape: GlassBackgroundModifier.GlassShape
    
    func body(content: Content) -> some View {
        switch shape {
        case .capsule:
            content
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        case .roundedRect(let radius):
            content
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Sheet Presentation Modifier

/// iOS 26: Remove background to let system apply Liquid Glass automatically
/// iOS 18: Use ultra thin material for translucent glass-like effect
struct GlassSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Don't set presentationBackground, system applies Liquid Glass automatically
            content
        } else {
            // iOS 18: Use material for glass-like effect
            content.presentationBackground(.ultraThinMaterial)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass background (Liquid Glass on iOS 26, Material on iOS 18)
    func glassBackground(shape: GlassBackgroundModifier.GlassShape = .capsule) -> some View {
        modifier(GlassBackgroundModifier(shape: shape))
    }
    
    /// Apply glass sheet background (System Liquid Glass on iOS 26, Material on iOS 18)
    func glassSheetBackground() -> some View {
        modifier(GlassSheetModifier())
    }
}
