//
//  CreateView.swift
//  Swipop
//
//  Project creation/editing view with platform-specific UI
//  - iOS 26: Native toolbar with Liquid Glass
//  - iOS 18: Custom glass-style top bar
//

import SwiftUI

struct CreateView: View {
    @Binding var showLogin: Bool
    @Bindable var projectEditor: ProjectEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Binding var selectedSubTab: CreateSubTab
    let onBack: () -> Void

    @State private var showOptions = false
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
            projectEditor: projectEditor,
            selectedSubTab: selectedSubTab,
            showOptions: $showOptions
        ))
        .sheet(isPresented: $showOptions) {
            ProjectOptionsSheet(projectEditor: projectEditor, chatViewModel: chatViewModel) {
                projectEditor.reset()
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
            ProjectPreviewView(projectEditor: projectEditor)
        case .html:
            RunestoneCodeView(language: .html, code: $projectEditor.html, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        case .css:
            RunestoneCodeView(language: .css, code: $projectEditor.css, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $projectEditor.javascript, isEditable: true)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Create Navigation Modifier

private struct CreateNavigationModifier: ViewModifier {
    let onBack: () -> Void
    @Bindable var projectEditor: ProjectEditorViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showOptions: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar { iOS26CreateToolbar(onBack: onBack, projectEditor: projectEditor, selectedSubTab: selectedSubTab, showOptions: $showOptions) }
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top) {
                    iOS18CreateTopBar(onBack: onBack, projectEditor: projectEditor, selectedSubTab: selectedSubTab, showOptions: $showOptions)
                }
        }
    }
}

// MARK: - Shared Toolbar Components

private struct CreateToolbarActions {
    @Bindable var projectEditor: ProjectEditorViewModel

    func toggleVisibility() {
        withAnimation(.spring(response: 0.3)) {
            projectEditor.isPublished.toggle()
            projectEditor.isDirty = true
        }
    }

    func save() {
        Task { await projectEditor.save() }
    }
}

// MARK: - iOS 26 Create Toolbar

@available(iOS 26.0, *)
private struct iOS26CreateToolbar: ToolbarContent {
    let onBack: () -> Void
    @Bindable var projectEditor: ProjectEditorViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showOptions: Bool

    private var actions: CreateToolbarActions {
        CreateToolbarActions(projectEditor: projectEditor)
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onBack) {
                Image(systemName: "xmark")
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            // Only show save button for code tabs (HTML, CSS, JS)
            if selectedSubTab.isCodeTab {
                Button(action: actions.save) {
                    HStack(spacing: 4) {
                        if projectEditor.isSaving {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: projectEditor.isDirty ? "circle.fill" : "checkmark")
                                .font(.system(size: 10))
                        }
                        Text(projectEditor.isSaving ? "Saving" : projectEditor.isDirty ? "Save" : "Saved")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(projectEditor.isDirty ? .orange : .green)
                }
                .disabled(projectEditor.isSaving || !projectEditor.isDirty)
            }

            Button(action: actions.toggleVisibility) {
                Image(systemName: projectEditor.isPublished ? "eye" : "eye.slash")
            }
            .tint(projectEditor.isPublished ? .green : .orange)

            Button { showOptions = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
}

// MARK: - iOS 18 Create Top Bar

private struct iOS18CreateTopBar: View {
    let onBack: () -> Void
    @Bindable var projectEditor: ProjectEditorViewModel
    let selectedSubTab: CreateSubTab
    @Binding var showOptions: Bool

    private let buttonWidth: CGFloat = 48
    private let buttonHeight: CGFloat = 44
    private let iconSize: CGFloat = 20

    private var actions: CreateToolbarActions {
        CreateToolbarActions(projectEditor: projectEditor)
    }

    var body: some View {
        HStack {
            // Back button (circular, matching ProjectViewerPage style)
            Button(action: onBack) {
                Image(systemName: "xmark")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: buttonHeight, height: buttonHeight)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5)
                    )
            }

            Spacer()

            // Action buttons group (matching ProjectViewerPage style)
            HStack(spacing: 0) {
                // Only show save button for code tabs
                if selectedSubTab.isCodeTab {
                    saveIndicator
                }
                glassIconButton(projectEditor.isPublished ? "eye" : "eye.slash", tint: projectEditor.isPublished ? .green : .orange, action: actions.toggleVisibility)
                glassIconButton("slider.horizontal.3", action: { showOptions = true })
            }
            .frame(height: buttonHeight)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
    }

    private var saveIndicator: some View {
        Button(action: actions.save) {
            HStack(spacing: 4) {
                if projectEditor.isSaving {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Image(systemName: projectEditor.isDirty ? "circle.fill" : "checkmark")
                        .font(.system(size: 8))
                }
                Text(projectEditor.isSaving ? "Saving" : projectEditor.isDirty ? "Save" : "Saved")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(projectEditor.isDirty ? .orange : .green)
            .frame(height: buttonHeight)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .disabled(projectEditor.isSaving || !projectEditor.isDirty)
    }

    private func glassIconButton(_ icon: String, tint: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: buttonWidth, height: buttonHeight)
                .contentShape(Rectangle())
        }
    }
}

#Preview {
    CreateViewPreview()
}

private struct CreateViewPreview: View {
    @State private var projectEditor = ProjectEditorViewModel()
    @State private var chatViewModel: ChatViewModel?

    var body: some View {
        NavigationStack {
            if let chat = chatViewModel {
                CreateView(showLogin: .constant(false), projectEditor: projectEditor, chatViewModel: chat, selectedSubTab: .constant(.chat), onBack: {})
            }
        }
        .onAppear {
            chatViewModel = ChatViewModel(projectEditor: projectEditor)
        }
    }
}
