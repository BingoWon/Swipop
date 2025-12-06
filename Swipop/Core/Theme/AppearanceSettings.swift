//
//  AppearanceSettings.swift
//  Swipop
//
//  App appearance/theme management
//

import SwiftUI

/// App appearance mode
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil // Follow system
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Global appearance settings
@MainActor
@Observable
final class AppearanceSettings {
    static let shared = AppearanceSettings()

    var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
        }
    }

    var colorScheme: ColorScheme? { mode.colorScheme }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        mode = AppearanceMode(rawValue: saved) ?? .system
    }
}
