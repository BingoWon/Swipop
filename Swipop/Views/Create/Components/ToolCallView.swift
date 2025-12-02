//
//  ToolCallView.swift
//  Swipop

import SwiftUI

struct ToolCallView: View {
    let toolCall: ChatMessage.ToolCallSegment
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            
            if isExpanded {
                details
            }
        }
        .background(Color.darkSheet)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var header: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconForTool)
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                
                Text("Called \(toolCall.name)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSection(title: "Arguments", content: toolCall.arguments, color: .white.opacity(0.8))
            
            if let result = toolCall.result {
                DetailSection(title: "Result", content: result, color: .green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
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
}

private struct DetailSection: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            Text(content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
