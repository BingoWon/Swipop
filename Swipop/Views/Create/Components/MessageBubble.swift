//
//  MessageBubble.swift
//  Swipop
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onRetry: (() -> Void)?
    
    @State private var isReasoningExpanded = false
    
    var body: some View {
        switch message.role {
        case .error:
            errorBubble
        case .user:
            userBubble
        case .assistant:
            assistantBubble
        }
    }
    
    // MARK: - User Message
    
    private var userBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: 60)
            
            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.userBubble)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    // MARK: - Assistant Message
    
    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            aiAvatar
            
            VStack(alignment: .leading, spacing: 8) {
                // Thinking indicator or expandable reasoning
                if message.isThinking {
                    thinkingIndicator
                } else if message.hasReasoning {
                    reasoningSection
                }
                
                // Main content (only show if not empty or not thinking)
                if !message.content.isEmpty || !message.isThinking {
                    contentBubble
                }
                
                // Tool call info
                if let toolCall = message.toolCall {
                    ToolCallView(toolCall: toolCall)
                }
            }
            
            Spacer(minLength: 60)
        }
    }
    
    private var aiAvatar: some View {
        Circle()
            .fill(.brandGradient)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: message.isThinking ? "brain.head.profile" : "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating, isActive: message.isThinking)
            }
    }
    
    // MARK: - Thinking Indicator
    
    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 12))
                .foregroundStyle(Color.brand)
            
            Text("Thinking")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            
            // Animated dots
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 4, height: 4)
                        .opacity(0.7)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: message.isThinking
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.brand.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Reasoning Section (Expandable)
    
    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isReasoningExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .font(.system(size: 11))
                    
                    Text("Thinking process")
                        .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(isReasoningExpanded ? 90 : 0))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // Expandable content
            if isReasoningExpanded {
                ScrollView {
                    Text(message.reasoning)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Content Bubble
    
    private var contentBubble: some View {
        Group {
            if message.content.isEmpty && message.isStreaming {
                Text("...")
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                RichMessageContent(content: message.content)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.assistantBubble)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Error Message
    
    private var errorBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                }
            
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
}
