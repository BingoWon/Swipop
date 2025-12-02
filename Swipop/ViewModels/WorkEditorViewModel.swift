//
//  WorkEditorViewModel.swift
//  Swipop
//
//  Shared state for work creation/editing
//

import SwiftUI

@MainActor
@Observable
final class WorkEditorViewModel {
    // MARK: - Content
    var html = ""
    var css = ""
    var javascript = ""
    
    // MARK: - Metadata
    var title = ""
    var description = ""
    var tags: [String] = []
    var isPublished = false
    
    // MARK: - State
    var isDirty = false
    var isSaving = false
    var lastSaved: Date?
    
    // MARK: - Computed
    var isEmpty: Bool { html.isEmpty && css.isEmpty && javascript.isEmpty }
    var hasContent: Bool { !isEmpty }
    
    // MARK: - Actions
    
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
