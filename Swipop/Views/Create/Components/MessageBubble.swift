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
        HStack {
            Spacer(minLength: 40)
            
            Text(message.userContent)
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(message.segments.enumerated()), id: \.offset) { index, segment in
                segmentView(segment, at: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                Text("...")
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.assistantBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                
                Text(message.errorContent)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private let iconWidth: CGFloat = 16
    
    @State private var isExpanded = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !info.text.isEmpty else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded && !info.text.isEmpty {
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
        .background(info.isActive ? Color.brand.opacity(0.12) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(info.isActive ? Color.brand.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear { if info.isActive { startTimer() } }
        .onDisappear { stopTimer() }
        .onChange(of: info.isActive) { _, isActive in
            if !isActive { stopTimer() }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            // Fixed-width icon container
            Image(systemName: "brain")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(info.isActive ? Color.brand : Color.brand.opacity(0.8))
                .symbolEffect(.pulse, options: .repeating, isActive: info.isActive)
                .frame(width: iconWidth)
            
            if info.isActive {
                Text("Thinking \(elapsedSeconds)s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                
                ShimmerBar()
            } else {
                Text("Thought for \(info.duration ?? 0)s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            if !info.text.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
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
