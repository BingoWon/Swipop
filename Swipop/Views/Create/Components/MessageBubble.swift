//
//  MessageBubble.swift
//  Swipop
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onRetry: (() -> Void)?
    
    var body: some View {
        if message.role == .error {
            errorBubble
        } else {
            standardBubble
        }
    }
    
    // MARK: - Standard Message
    
    private var standardBubble: some View {
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
    
    // MARK: - Error Message
    
    private var errorBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            errorIcon
            
            VStack(alignment: .leading, spacing: 10) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                
                if let onRetry {
                    Button(action: onRetry) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                            Text("Retry")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer(minLength: 40)
        }
        .padding(12)
        .background(Color.red.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var errorIcon: some View {
        Circle()
            .fill(Color.red.opacity(0.2))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
            }
    }
}
