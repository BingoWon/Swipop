//
//  ToolCallView.swift
//  Swipop

import SwiftUI

struct ToolCallView: View {
    let toolCall: ChatMessage.ToolCallSegment
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            // Only expand when manually toggled
            if isExpanded && !toolCall.arguments.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                argumentsContent
                
                if let result = toolCall.result {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    resultContent(result)
                }
            }
        }
        .background(Color.darkSheet)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toolCall.isStreaming ? Color.orange.opacity(0.4) : Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            // Icon
            if toolCall.isStreaming {
                Image(systemName: iconForTool)
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating, isActive: true)
            } else {
                Image(systemName: iconForTool)
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            }
            
            // Status text
            if toolCall.isStreaming {
                Text("Calling \(displayName)...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.orange)
            } else {
                Text("Called \(displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            // Show chevron if there's content
            if !toolCall.arguments.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
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
                .foregroundStyle(.white.opacity(0.5))
            
            ScrollView {
                Text(toolCall.arguments)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
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
                .foregroundStyle(.white.opacity(0.5))
            
            Text(result)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private var iconForTool: String {
        switch toolCall.name {
        case "edit_html": "chevron.left.forwardslash.chevron.right"
        case "edit_css": "paintbrush"
        case "edit_javascript": "curlybraces"
        case "update_metadata": "text.badge.star"
        default: "wrench"
        }
    }
    
    private var displayName: String {
        switch toolCall.name {
        case "edit_html": "edit_html"
        case "edit_css": "edit_css"
        case "edit_javascript": "edit_javascript"
        case "update_metadata": "update_metadata"
        default: toolCall.name
        }
    }
}
