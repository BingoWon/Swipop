//
//  MessageBubble.swift
//  Swipop

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onRetry: (() -> Void)?
    
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
            
            Text(message.userContent)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.userBubble)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    // MARK: - Assistant Message (single avatar, multiple segments)
    
    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            aiAvatar
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(message.segments.enumerated()), id: \.offset) { index, segment in
                    segmentView(segment, at: index)
                }
            }
            
            Spacer(minLength: 60)
        }
    }
    
    @ViewBuilder
    private func segmentView(_ segment: ChatMessage.Segment, at index: Int) -> some View {
        switch segment {
        case .thinking(let info):
            ThinkingSegmentView(info: info)
        case .toolCall(let info):
            ToolCallView(toolCall: info)
        case .content(let text):
            if !text.isEmpty {
                contentBubble(text)
            } else if message.isStreaming && index == message.segments.count - 1 {
                // Show placeholder only for last segment while streaming
                Text("...")
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.assistantBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
    
    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(.brandGradient)
                .frame(width: 32, height: 32)
            
            if message.isActivelyThinking {
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
    
    private func contentBubble(_ text: String) -> some View {
        RichMessageContent(content: text)
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
                Text(message.errorContent)
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

// MARK: - Thinking Segment View

struct ThinkingSegmentView: View {
    let info: ChatMessage.ThinkingSegment
    
    @State private var isExpanded = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    
    var body: some View {
        if info.isActive {
            activeThinkingView
                .onAppear { startTimer() }
                .onDisappear { stopTimer() }
        } else if !info.text.isEmpty {
            completedThinkingView
        }
    }
    
    // MARK: - Active Thinking
    
    private var activeThinkingView: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.brand)
                .symbolEffect(.pulse, options: .repeating, isActive: true)
            
            Text("Thinking")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("\(elapsedSeconds)s")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.brand)
                .contentTransition(.numericText())
            
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
    
    // MARK: - Completed Thinking
    
    private var completedThinkingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brand.opacity(0.8))
                
                Text("Thought for \(info.duration ?? 0)s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    Text(info.text)
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
    
    // MARK: - Timer
    
    private func startTimer() {
        if let start = info.startTime {
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
}

// MARK: - Shimmer Bar

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
