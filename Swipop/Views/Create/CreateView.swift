//
//  CreateView.swift
//  Swipop
//

import SwiftUI

struct CreateView: View {
    @Binding var showLogin: Bool
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Binding var selectedSubTab: CreateSubTab
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if AuthService.shared.isAuthenticated {
                    content
                } else {
                    signInPrompt
                }
            }
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings) {
            WorkSettingsSheet(workEditor: workEditor, chatViewModel: chatViewModel) {
                workEditor.reset()
                chatViewModel.clear()
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if selectedSubTab == .chat {
            ToolbarItem(placement: .topBarLeading) {
                modelSelector
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedSubTab != .chat {
                saveButton
            }
            visibilityButton
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
    
    private var modelSelector: some View {
        Menu {
            ForEach(AIModel.allCases) { model in
                Button(model.displayName) {
                    chatViewModel.selectedModel = model
                }
            }
        } label: {
            Text(chatViewModel.selectedModel.displayName)
                .font(.system(size: 13, weight: .medium))
        }
    }
    
    private var saveButton: some View {
        Button { Task { await workEditor.save() } } label: {
            HStack(spacing: 4) {
                if workEditor.isSaving {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Image(systemName: workEditor.isDirty ? "circle.fill" : "checkmark")
                        .font(.system(size: 10))
                }
                Text(workEditor.isSaving ? "Saving" : workEditor.isDirty ? "Save" : "Saved")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(workEditor.isDirty ? .orange : .green)
        }
        .disabled(workEditor.isSaving || !workEditor.isDirty)
    }
    
    private var visibilityButton: some View {
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
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch selectedSubTab {
        case .chat:
            ChatEditorView(chatViewModel: chatViewModel, showSuggestions: true, isInputFocused: $isInputFocused)
        case .preview:
            WorkPreviewView(workEditor: workEditor)
        case .html:
            RunestoneCodeView(language: .html, code: $workEditor.html, isEditable: true)
                .ignoresSafeArea()
        case .css:
            RunestoneCodeView(language: .css, code: $workEditor.css, isEditable: true)
                .ignoresSafeArea()
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $workEditor.javascript, isEditable: true)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Sign In Prompt
    
    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Sign in to create")
                .font(.title2)
                .foregroundStyle(.primary)
            
            Button { showLogin = true } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brand)
                    .cornerRadius(25)
            }
        }
    }
}

#Preview {
    CreateViewPreview()
}

private struct CreateViewPreview: View {
    @State private var workEditor = WorkEditorViewModel()
    @State private var chatViewModel: ChatViewModel?
    
    var body: some View {
        Group {
            if let chat = chatViewModel {
                CreateView(showLogin: .constant(false), workEditor: workEditor, chatViewModel: chat, selectedSubTab: .constant(.chat))
            }
        }
        .onAppear {
            chatViewModel = ChatViewModel(workEditor: workEditor)
        }
    }
}
