//
//  CreateView.swift
//  Swipop
//

import SwiftUI

struct CreateView: View {
    @Binding var showLogin: Bool
    @Bindable var workEditor: WorkEditorViewModel
    @State private var chatViewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            LinearGradient.darkBackgroundGradient.ignoresSafeArea()
            
            if AuthService.shared.isAuthenticated {
                content
            } else {
                signInPrompt
            }
        }
        .sheet(isPresented: $chatViewModel.showModelPicker) {
            ModelPickerSheet(selectedModel: $chatViewModel.selectedModel)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.darkSheet)
        }
        .alert("Error", isPresented: .init(
            get: { chatViewModel.error != nil },
            set: { if !$0 { chatViewModel.error = nil } }
        )) {
            Button("OK") { chatViewModel.error = nil }
        } message: {
            Text(chatViewModel.error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Content Switcher
    
    @ViewBuilder
    private var content: some View {
        switch workEditor.selectedTab {
        case .chat:
            chatInterface
        case .preview:
            WorkPreviewView(
                html: workEditor.html,
                css: workEditor.css,
                javascript: workEditor.javascript
            )
        case .html:
            CodeEditorView(language: .html, code: $workEditor.html)
        case .css:
            CodeEditorView(language: .css, code: $workEditor.css)
        case .javascript:
            CodeEditorView(language: .javascript, code: $workEditor.javascript)
        }
    }
    
    // MARK: - Chat Interface
    
    private var chatInterface: some View {
        VStack(spacing: 0) {
            header
            messageList
            inputBar
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Create with AI")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                modelSelector
            }
            
            Spacer()
            
            Button { chatViewModel.clear() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
    }
    
    private var modelSelector: some View {
        Button { chatViewModel.showModelPicker = true } label: {
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Image(systemName: chatViewModel.selectedModel.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.brand)
                Text(chatViewModel.selectedModel.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if chatViewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(message: message)
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
    
    private var emptyState: some View {
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
                
                Text("Ask me to generate code, search works, or just chat!")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                suggestionChip("✨ Create a glowing button animation")
                suggestionChip("🔍 Search for particle effects")
                suggestionChip("🌤️ What's the weather in Tokyo?")
            }
            .padding(.top, 16)
            
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
            
            Button {
                chatViewModel.send()
                isInputFocused = false
            } label: {
                Circle()
                    .fill(chatViewModel.inputText.isEmpty
                          ? LinearGradient(colors: [.white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                          : .brandGradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if chatViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .disabled(chatViewModel.inputText.isEmpty || chatViewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Sign In Prompt
    
    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Sign in to create")
                .font(.title2)
                .foregroundColor(.white)
            
            Button { showLogin = true } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
            }
        }
    }
}

#Preview {
    CreateView(showLogin: .constant(false), workEditor: WorkEditorViewModel())
        .preferredColorScheme(.dark)
}
