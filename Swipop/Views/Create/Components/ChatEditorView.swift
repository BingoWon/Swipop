//
//  ChatEditorView.swift
//  Swipop
//
//  Shared chat interface component for CreateView and WorkEditSheet
//

import SwiftUI

struct ChatEditorView: View {
    @Bindable var chatViewModel: ChatViewModel
    var showSuggestions = true
    @FocusState.Binding var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if chatViewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                onRetry: message.role == .error ? { chatViewModel.retry() } : nil
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: chatViewModel.messages.count) { _, _ in
                if let last = chatViewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        if showSuggestions {
            newWorkEmptyState
        } else {
            continueEmptyState
        }
    }
    
    private var newWorkEmptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            ZStack {
                Circle()
                    .fill(.brandGradient)
                    .frame(width: 80, height: 80)
                    .blur(radius: 30)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.brandGradient)
            }
            
            VStack(spacing: 8) {
                Text("What would you like to create?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("Describe your idea and I'll generate the code!")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                suggestionChip("✨ Create a glowing button animation")
                suggestionChip("🎨 Make a gradient background effect")
                suggestionChip("🌊 Build an animated wave loader")
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    private var continueEmptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("Continue your conversation")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            Text("Ask AI to modify or improve this work")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            
            Spacer()
        }
    }
    
    private func suggestionChip(_ text: String) -> some View {
        Button {
            chatViewModel.inputText = String(text.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            chatViewModel.send()
        } label: {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $chatViewModel.inputText, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .tint(Color.brand)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1))
            
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.5))
    }
    
    private var sendButton: some View {
        Button {
            if chatViewModel.isLoading {
                chatViewModel.stop()
            } else {
                chatViewModel.send()
                isInputFocused = false
            }
        } label: {
            Circle()
                .fill(chatViewModel.isLoading || !chatViewModel.inputText.isEmpty
                      ? .brandGradient
                      : LinearGradient(colors: [.white.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: chatViewModel.isLoading ? "stop.fill" : "arrow.up")
                        .font(.system(size: chatViewModel.isLoading ? 16 : 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .disabled(!chatViewModel.isLoading && chatViewModel.inputText.isEmpty)
    }
}

