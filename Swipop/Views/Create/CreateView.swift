//
//  CreateView.swift
//  Swipop
//

import SwiftUI

struct CreateView: View {
    @Binding var showLogin: Bool
    @Bindable var workEditor: WorkEditorViewModel
    @Binding var selectedSubTab: CreateSubTab
    @State private var chatViewModel = ChatViewModel()
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.darkBackgroundGradient.ignoresSafeArea()
                
                if AuthService.shared.isAuthenticated {
                    content
                } else {
                    signInPrompt
                }
            }
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $chatViewModel.showModelPicker) {
            ModelPickerSheet(selectedModel: $chatViewModel.selectedModel)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.darkSheet)
        }
        .sheet(isPresented: $showSettings) {
            WorkSettingsSheet(workEditor: workEditor) {
                // Delete work: reset editor and clear chat
                workEditor.reset()
                chatViewModel.clear()
            }
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
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Leading: Model selector (Chat only)
        if selectedSubTab == .chat {
            ToolbarItem(placement: .topBarLeading) {
                modelSelector
            }
        }
        
        // Trailing: Save (non-chat pages only), Visibility, Options
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Save indicator (only for non-chat pages)
            if selectedSubTab != .chat {
                Button(action: handleSave) {
                    HStack(spacing: 4) {
                        if workEditor.isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: workEditor.isDirty ? "circle.fill" : "checkmark")
                                .font(.system(size: 10))
                        }
                        Text(saveStatusText)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(workEditor.isDirty ? .orange : .green)
                }
                .disabled(workEditor.isSaving || !workEditor.isDirty)
            }
            
            // Visibility toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    workEditor.isPublished.toggle()
                    workEditor.isDirty = true
                }
            } label: {
                Image(systemName: workEditor.isPublished ? "eye" : "eye.slash")
            }
            .tint(workEditor.isPublished ? .green : .orange)
        }
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        // Work options
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
    
    private var saveStatusText: String {
        if workEditor.isSaving { return "Saving" }
        if workEditor.isDirty { return "Save" }
        return "Saved"
    }
    
    private func handleSave() {
        Task { await workEditor.save() }
    }
    
    // MARK: - Content Switcher
    
    @ViewBuilder
    private var content: some View {
        switch selectedSubTab {
        case .chat:
            chatInterface
        case .preview:
            WorkPreviewView(
                html: workEditor.html,
                css: workEditor.css,
                javascript: workEditor.javascript
            )
        case .html:
            RunestoneCodeView(language: .html, code: $workEditor.html, isEditable: true)
        case .css:
            RunestoneCodeView(language: .css, code: $workEditor.css, isEditable: true)
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $workEditor.javascript, isEditable: true)
        }
    }
    
    // MARK: - Chat Interface
    
    private var chatInterface: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
    }
    
    private var modelSelector: some View {
        Menu {
            ForEach(AIModel.allCases) { model in
                Button {
                    chatViewModel.selectedModel = model
                } label: {
                    Label(model.displayName, systemImage: model.icon)
                }
            }
        } label: {
            Label {
                Text(chatViewModel.selectedModel.displayName)
            } icon: {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Image(systemName: chatViewModel.selectedModel.icon)
                }
            }
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
    CreateView(showLogin: .constant(false), workEditor: WorkEditorViewModel(), selectedSubTab: .constant(.chat))
        .preferredColorScheme(.dark)
}
