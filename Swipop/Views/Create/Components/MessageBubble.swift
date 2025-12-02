//
//  MessageBubble.swift
//  Swipop
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onRetry: (() -> Void)?
    
    @State private var isReasoningExpanded = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    
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
                // Thinking: active or completed
                if message.isThinking {
                    activeThinkingView
                } else if message.hasReasoning {
                    completedThinkingView
                }
                
                // Main content
                if !message.content.isEmpty || (!message.isThinking && !message.hasReasoning) {
                    contentBubble
                }
                
                // Tool call
                if let toolCall = message.toolCall {
                    ToolCallView(toolCall: toolCall)
                }
            }
            
            Spacer(minLength: 60)
        }
        .onAppear { startTimerIfNeeded() }
        .onDisappear { stopTimer() }
        .onChange(of: message.isThinking) { _, isThinking in
            if !isThinking { stopTimer() }
        }
    }
    
    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(.brandGradient)
                .frame(width: 32, height: 32)
            
            if message.isThinking {
                // Animated brain during thinking
                Image(systemName: "brain")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating.speed(0.5), isActive: true)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Active Thinking (with live timer)
    
    private var activeThinkingView: some View {
        HStack(spacing: 8) {
            // Pulsing brain icon
            Image(systemName: "brain")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.brand)
                .symbolEffect(.pulse, options: .repeating, isActive: true)
            
            Text("Thinking")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            
            // Live elapsed time
            Text("\(elapsedSeconds)s")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.brand)
                .contentTransition(.numericText())
            
            // Animated shimmer bar
            ShimmerBar()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.brand.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brand.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Completed Thinking (expandable)
    
    private var completedThinkingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - tappable
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brand.opacity(0.8))
                
                Text("Thought for \(message.thinkingDuration ?? 0)s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .rotationEffect(.degrees(isReasoningExpanded ? 90 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isReasoningExpanded.toggle()
                }
            }
            
            // Expandable content
            if isReasoningExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    Text(message.reasoning)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Content Bubble
    
    private var contentBubble: some View {
        Group {
            if message.content.isEmpty && message.isStreaming {
                Text("...")
                    .foregroundStyle(.white.opacity(0.5))
            } else if !message.content.isEmpty {
                RichMessageContent(content: message.content)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.assistantBubble)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Timer
    
    private func startTimerIfNeeded() {
        guard message.isThinking, timer == nil else { return }
        
        // Initialize elapsed time
        if let start = message.thinkingStartTime {
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                elapsedSeconds += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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

// MARK: - Shimmer Animation Bar

private struct ShimmerBar: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.brand.opacity(0.3))
            .frame(width: 40, height: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.brand, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 20)
                    .offset(x: phase)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    phase = 30
                }
            }
    }
}
