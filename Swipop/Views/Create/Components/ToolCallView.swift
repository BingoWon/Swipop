//
//  ToolCallView.swift
//  Swipop

import SwiftUI

struct ToolCallView: View {
    let toolCall: ChatMessage.ToolCallSegment

    private let iconWidth: CGFloat = 16

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded && !toolCall.arguments.isEmpty {
                Divider()
                    .background(Color.border)

                argumentsContent

                if let result = toolCall.result {
                    Divider()
                        .background(Color.border)

                    resultContent(result)
                }
            }
        }
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toolCall.isStreaming ? Color.orange.opacity(0.4) : Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            // Fixed-width icon container
            Image(systemName: iconForTool)
                .font(.system(size: 12))
                .foregroundStyle(toolCall.isStreaming ? .orange : .green)
                .symbolEffect(.pulse, options: .repeating, isActive: toolCall.isStreaming)
                .frame(width: iconWidth)

            // Status text - consistent layout for both states
            Text(toolCall.isStreaming ? "Calling \(displayName)..." : "Called \(displayName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.9))

            // Always reserve space for ProgressView to maintain consistent height
            ProgressView()
                .scaleEffect(0.6)
                .tint(.orange)
                .opacity(toolCall.isStreaming ? 1 : 0)

            if !toolCall.arguments.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !toolCall.arguments.isEmpty else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
    }

    private var argumentsContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(toolCall.isStreaming ? "Arguments (streaming...)" : "Arguments")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(toolCall.arguments)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func resultContent(_ result: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Result")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text(result)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var iconForTool: String {
        if toolCall.name.contains("html") { return "chevron.left.forwardslash.chevron.right" }
        if toolCall.name.contains("css") { return "paintbrush" }
        if toolCall.name.contains("javascript") { return "curlybraces" }
        if toolCall.name.contains("metadata") { return "text.badge.star" }
        return "wrench"
    }

    private var displayName: String {
        toolCall.name
    }
}
