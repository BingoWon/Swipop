//
//  MessageBubble.swift
//  Swipop
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                aiAvatar
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                contentBubble
                
                if let toolCall = message.toolCall {
                    ToolCallView(toolCall: toolCall)
                }
                
                if message.isStreaming {
                    streamingIndicator
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var aiAvatar: some View {
        Circle()
            .fill(.brandGradient)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
    }
    
    private var contentBubble: some View {
        Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.role == .user ? Color.userBubble : Color.assistantBubble)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var streamingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.brand)
                    .frame(width: 6, height: 6)
                    .opacity(0.7)
            }
        }
        .padding(.horizontal, 8)
    }
}
