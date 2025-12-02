//
//  WorkEditorViewModel.swift
//  Swipop
//
//  Shared state for work creation/editing across all sub-tabs
//

import SwiftUI

@MainActor
@Observable
final class WorkEditorViewModel {
    // MARK: - Work Content
    var html: String = ""
    var css: String = ""
    var javascript: String = ""
    
    // MARK: - Metadata
    var title: String = ""
    var description: String = ""
    var tags: [String] = []
    var isPublished: Bool = false
    
    // MARK: - State
    var isDirty: Bool = false
    var isSaving: Bool = false
    var lastSaved: Date?
    
    // MARK: - Computed
    var isEmpty: Bool {
        html.isEmpty && css.isEmpty && javascript.isEmpty
    }
    
    var hasContent: Bool { !isEmpty }
    
    // MARK: - Actions
    
    func updateHTML(_ content: String) {
        html = content
        isDirty = true
    }
    
    func updateCSS(_ content: String) {
        css = content
        isDirty = true
    }
    
    func updateJavaScript(_ content: String) {
        javascript = content
        isDirty = true
    }
    
    func save() async {
        guard isDirty else { return }
        isSaving = true
        defer { isSaving = false }
        
        // TODO: Save to Supabase
        try? await Task.sleep(for: .milliseconds(500))
        
        isDirty = false
        lastSaved = Date()
    }
    
    func reset() {
        html = ""
        css = ""
        javascript = ""
        title = ""
        description = ""
        tags = []
        isPublished = false
        isDirty = false
        lastSaved = nil
    }
}

