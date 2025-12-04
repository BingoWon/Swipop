//
//  CreateView.swift
//  Swipop
//
//  Work creation/editing view with platform-specific UI
//  - iOS 26: Native toolbar with Liquid Glass
//  - iOS 18: Custom glass-style top bar
//

import SwiftUI

struct CreateView: View {
    @Binding var showLogin: Bool
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Binding var selectedSubTab: CreateSubTab
    let onBack: () -> Void
    
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            if AuthService.shared.isAuthenticated {
                content
                    .safeAreaInset(edge: .bottom) {
                        Spacer().frame(height: 60)
                    }
            } else {
                signInPrompt
            }
            
            if AuthService.shared.isAuthenticated {
                FloatingCreateAccessory(selectedSubTab: $selectedSubTab)
            }
        }
        .modifier(CreateNavigationModifier(
            onBack: onBack,
            workEditor: workEditor,
            chatViewModel: chatViewModel,
            selectedSubTab: selectedSubTab,
            showSettings: $showSettings
        ))
        .sheet(isPresented: $showSettings) {
            WorkSettingsSheet(workEditor: workEditor, chatViewModel: chatViewModel) {
                workEditor.reset()
                chatViewModel.clear()
            }
        }
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
                .ignoresSafeArea(edges: .bottom)
        case .css:
            RunestoneCodeView(language: .css, code: $workEditor.css, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $workEditor.javascript, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
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

// MARK: - Create Navigation Modifier

private struct CreateNavigationModifier: ViewModifier {
    let onBack: () -> Void
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showSettings: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar { iOS26CreateToolbar(onBack: onBack, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: selectedSubTab, showSettings: $showSettings) }
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top) {
                    iOS18CreateTopBar(onBack: onBack, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: selectedSubTab, showSettings: $showSettings)
                }
        }
    }
}

// MARK: - Shared Toolbar Components

private struct CreateToolbarActions {
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    
    func toggleVisibility() {
        withAnimation(.spring(response: 0.3)) {
            workEditor.isPublished.toggle()
            workEditor.isDirty = true
        }
    }
    
    func save() {
        Task { await workEditor.save() }
    }
    
    func selectModel(_ model: AIModel) {
        chatViewModel.selectedModel = model
    }
}

// MARK: - iOS 26 Create Toolbar

@available(iOS 26.0, *)
private struct iOS26CreateToolbar: ToolbarContent {
    let onBack: () -> Void
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showSettings: Bool
    
    private var actions: CreateToolbarActions {
        CreateToolbarActions(workEditor: workEditor, chatViewModel: chatViewModel)
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onBack) {
                Image(systemName: "xmark")
            }
        }
        
        if selectedSubTab == .chat {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    ForEach(AIModel.allCases) { model in
                        Button(model.displayName) { actions.selectModel(model) }
                    }
                } label: {
                    Text(chatViewModel.selectedModel.displayName)
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedSubTab != .chat {
                Button(action: actions.save) {
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
            
            Button(action: actions.toggleVisibility) {
                Image(systemName: workEditor.isPublished ? "eye" : "eye.slash")
            }
            .tint(workEditor.isPublished ? .green : .orange)
            
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
}

// MARK: - iOS 18 Create Top Bar

private struct iOS18CreateTopBar: View {
    let onBack: () -> Void
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showSettings: Bool
    
    private let buttonHeight: CGFloat = 44
    private let iconSize: CGFloat = 20
    
    private var actions: CreateToolbarActions {
        CreateToolbarActions(workEditor: workEditor, chatViewModel: chatViewModel)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            glassCircleButton("xmark", action: onBack)
            
            if selectedSubTab == .chat {
                modelSelector
            }
            
            Spacer()
            
            actionButtonGroup
        }
        .padding(.horizontal, 16)
    }
    
    private func glassCircleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: buttonHeight, height: buttonHeight)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
    }
    
    private var modelSelector: some View {
        Menu {
            ForEach(AIModel.allCases) { model in
                Button(model.displayName) { actions.selectModel(model) }
            }
        } label: {
            Text(chatViewModel.selectedModel.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .frame(height: buttonHeight)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
    }
    
    private var actionButtonGroup: some View {
        HStack(spacing: 0) {
            if selectedSubTab != .chat {
                saveIndicator
                Divider().frame(height: 18).overlay(Color.border)
            }
            
            visibilityButton
            Divider().frame(height: 18).overlay(Color.border)
            settingsButton
        }
        .frame(height: buttonHeight)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
    }
    
    private var saveIndicator: some View {
        Button(action: actions.save) {
            HStack(spacing: 4) {
                if workEditor.isSaving {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Image(systemName: workEditor.isDirty ? "circle.fill" : "checkmark")
                        .font(.system(size: 8))
                }
                Text(workEditor.isSaving ? "Saving" : workEditor.isDirty ? "Save" : "Saved")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(workEditor.isDirty ? .orange : .green)
            .frame(height: buttonHeight)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .disabled(workEditor.isSaving || !workEditor.isDirty)
    }
    
    private var visibilityButton: some View {
        Button(action: actions.toggleVisibility) {
            Image(systemName: workEditor.isPublished ? "eye" : "eye.slash")
                .font(.system(size: iconSize - 2, weight: .medium))
                .foregroundStyle(workEditor.isPublished ? .green : .orange)
                .frame(width: buttonHeight, height: buttonHeight)
                .contentShape(Rectangle())
        }
    }
    
    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: iconSize - 2, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: buttonHeight, height: buttonHeight)
                .contentShape(Rectangle())
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
        NavigationStack {
            if let chat = chatViewModel {
                CreateView(showLogin: .constant(false), workEditor: workEditor, chatViewModel: chat, selectedSubTab: .constant(.chat), onBack: {})
            }
        }
        .onAppear {
            chatViewModel = ChatViewModel(workEditor: workEditor)
        }
    }
}
