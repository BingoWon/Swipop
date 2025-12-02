//
//  WorkEditorSheet.swift
//  Swipop
//
//  Sheet for editing an existing work
//

import SwiftUI

struct WorkEditorSheet: View {
    let work: Work
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var selectedSubTab: CreateSubTab = .chat
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    
    init(work: Work, onDismiss: @escaping () -> Void) {
        self.work = work
        self.onDismiss = onDismiss
        
        let editor = WorkEditorViewModel()
        editor.load(work: work)
        self._workEditor = State(initialValue: editor)
        self._chatViewModel = State(initialValue: ChatViewModel(workEditor: editor))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.darkBackgroundGradient.ignoresSafeArea()
                content
            }
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                // Load chat history from work
                chatViewModel.loadFromWorkEditor()
            }
        }
        .sheet(isPresented: $showSettings) {
            WorkSettingsSheet(workEditor: workEditor) {
                // Delete work
                Task {
                    try? await WorkService.shared.deleteWork(id: work.id)
                    dismiss()
                    onDismiss()
                }
            }
        }
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom) {
            CreateSubTabBar(selectedTab: $selectedSubTab)
                .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { 
                dismiss()
                onDismiss()
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Save indicator
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
}

#Preview {
    WorkEditorSheet(work: .sample) {}
        .preferredColorScheme(.dark)
}

