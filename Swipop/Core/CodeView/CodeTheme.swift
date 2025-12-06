//
//  CodeTheme.swift
//  Swipop
//
//  Adaptive theme for Runestone code views (Light/Dark)
//

import Runestone
import SwiftUI

final class CodeTheme: Runestone.Theme {
    // MARK: - Configuration

    private let fontSize: CGFloat
    private let isDark: Bool

    init(fontSize: CGFloat = 14, colorScheme: ColorScheme = .dark) {
        self.fontSize = fontSize
        isDark = colorScheme == .dark
    }

    // MARK: - Fonts

    var font: UIFont { .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    var lineNumberFont: UIFont { .monospacedSystemFont(ofSize: fontSize - 2, weight: .regular) }

    // MARK: - Colors (Adaptive)

    var textColor: UIColor {
        isDark ? UIColor(Color(hex: "e6edf3")) : UIColor(Color(hex: "24292f"))
    }

    var gutterBackgroundColor: UIColor {
        isDark ? UIColor(Color(hex: "0d1117")) : UIColor(Color(hex: "f6f8fa"))
    }

    var gutterHairlineColor: UIColor {
        isDark ? UIColor(Color(hex: "30363d")) : UIColor(Color(hex: "d0d7de"))
    }

    var lineNumberColor: UIColor {
        isDark ? UIColor(Color(hex: "6e7681")) : UIColor(Color(hex: "8c959f"))
    }

    var selectedLineBackgroundColor: UIColor {
        isDark ? UIColor(Color(hex: "161b22")) : UIColor(Color(hex: "fff8c5"))
    }

    var selectedLinesLineNumberColor: UIColor {
        isDark ? UIColor(Color(hex: "e6edf3")) : UIColor(Color(hex: "24292f"))
    }

    var selectedLinesGutterBackgroundColor: UIColor {
        isDark ? UIColor(Color(hex: "161b22")) : UIColor(Color(hex: "fff8c5"))
    }

    var invisibleCharactersColor: UIColor {
        isDark ? UIColor(Color(hex: "484f58")) : UIColor(Color(hex: "a8b1bb"))
    }

    var pageGuideHairlineColor: UIColor {
        isDark ? UIColor(Color(hex: "30363d")) : UIColor(Color(hex: "d0d7de"))
    }

    var pageGuideBackgroundColor: UIColor {
        isDark ? UIColor(Color(hex: "161b22")) : UIColor(Color(hex: "f6f8fa"))
    }

    var markedTextBackgroundColor: UIColor {
        isDark ? UIColor(Color(hex: "388bfd").opacity(0.3)) : UIColor(Color(hex: "0969da").opacity(0.2))
    }

    // MARK: - Syntax Highlighting (Adaptive)

    func textColor(for highlightName: String) -> UIColor? {
        if isDark {
            return darkTextColor(for: highlightName)
        } else {
            return lightTextColor(for: highlightName)
        }
    }

    // Dark theme colors (GitHub Dark)
    private func darkTextColor(for highlightName: String) -> UIColor? {
        switch highlightName {
        case "keyword", "keyword.control", "keyword.function", "keyword.operator":
            return UIColor(Color(hex: "ff7b72"))
        case "string", "string.special", "escape":
            return UIColor(Color(hex: "a5d6ff"))
        case "comment", "comment.block", "comment.line":
            return UIColor(Color(hex: "8b949e"))
        case "function", "function.method", "method":
            return UIColor(Color(hex: "d2a8ff"))
        case "type", "type.builtin", "class", "constructor":
            return UIColor(Color(hex: "ffa657"))
        case "variable", "variable.builtin", "property", "attribute", "attribute.builtin":
            return UIColor(Color(hex: "79c0ff"))
        case "constant", "constant.builtin", "number", "boolean":
            return UIColor(Color(hex: "79c0ff"))
        case "tag", "tag.builtin":
            return UIColor(Color(hex: "7ee787"))
        case "operator", "punctuation", "punctuation.bracket", "punctuation.delimiter":
            return UIColor(Color(hex: "e6edf3"))
        default:
            return nil
        }
    }

    // Light theme colors (GitHub Light)
    private func lightTextColor(for highlightName: String) -> UIColor? {
        switch highlightName {
        case "keyword", "keyword.control", "keyword.function", "keyword.operator":
            return UIColor(Color(hex: "cf222e"))
        case "string", "string.special", "escape":
            return UIColor(Color(hex: "0a3069"))
        case "comment", "comment.block", "comment.line":
            return UIColor(Color(hex: "6e7781"))
        case "function", "function.method", "method":
            return UIColor(Color(hex: "8250df"))
        case "type", "type.builtin", "class", "constructor":
            return UIColor(Color(hex: "953800"))
        case "variable", "variable.builtin", "property", "attribute", "attribute.builtin":
            return UIColor(Color(hex: "0550ae"))
        case "constant", "constant.builtin", "number", "boolean":
            return UIColor(Color(hex: "0550ae"))
        case "tag", "tag.builtin":
            return UIColor(Color(hex: "116329"))
        case "operator", "punctuation", "punctuation.bracket", "punctuation.delimiter":
            return UIColor(Color(hex: "24292f"))
        default:
            return nil
        }
    }

    func fontTraits(for highlightName: String) -> FontTraits {
        switch highlightName {
        case "keyword", "keyword.control":
            return .bold
        case "comment", "comment.block", "comment.line":
            return .italic
        default:
            return []
        }
    }
}
