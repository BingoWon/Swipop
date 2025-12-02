//
//  WorkEditSheet.swift
//  Swipop
//
//  Sheet for editing an existing work
//

import SwiftUI

struct WorkEditSheet: View {
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
            .onAppear { chatViewModel.loadFromWorkEditor() }
        }
        .sheet(isPresented: $showSettings) {
            WorkSettingsSheet(workEditor: workEditor) {
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
            saveButton
            visibilityButton
        }
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
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
            ChatEditorView(chatViewModel: chatViewModel, showSuggestions: false, isInputFocused: $isInputFocused)
        case .preview:
            WorkPreviewView(html: workEditor.html, css: workEditor.css, javascript: workEditor.javascript)
        case .html:
            RunestoneCodeView(language: .html, code: $workEditor.html, isEditable: true)
        case .css:
            RunestoneCodeView(language: .css, code: $workEditor.css, isEditable: true)
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $workEditor.javascript, isEditable: true)
        }
    }
}

#Preview {
    WorkEditSheet(work: .sample) {}
        .preferredColorScheme(.dark)
}

