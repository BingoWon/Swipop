//
//  WorkOptionsSheet.swift
//  Swipop
//
//  Sheet for editing work metadata and visibility
//

import SwiftUI
import PhotosUI

struct WorkOptionsSheet: View {
    @Bindable var workEditor: WorkEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var tagInput = ""
    @State private var showDeleteConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Thumbnail
                Section {
                    thumbnailEditor
                } header: {
                    Label("Thumbnail", systemImage: "photo")
                }
                
                // Details
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("Enter title", text: $workEditor.title)
                            .font(.system(size: 16))
                    }
                    .listRowBackground(Color.secondaryBackground.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        TextField("Enter description", text: $workEditor.description, axis: .vertical)
                            .font(.system(size: 16))
                            .lineLimit(3...6)
                    }
                    .listRowBackground(Color.secondaryBackground.opacity(0.5))
                } header: {
                    Label("Details", systemImage: "doc.text")
                }
                
                // Tags
                Section {
                    tagsEditor
                } header: {
                    Label("Tags", systemImage: "tag")
                }
                
                // Visibility
                Section {
                    visibilityPicker
                } header: {
                    Label("Visibility", systemImage: "eye")
                }
                
                // AI Model
                Section {
                    modelPicker
                } header: {
                    Label("AI Model", systemImage: "cpu")
                }
                
                // Context Window
                Section {
                    contextWindowView
                } header: {
                    Label("Context", systemImage: "brain")
                } footer: {
                    Text("Auto-summarize is always enabled. When context reaches capacity, conversation will be automatically compacted to continue.")
                        .font(.system(size: 12))
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Work")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Work Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isSaving = true
                            await workEditor.save()
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .confirmationDialog(
                "Delete this work?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your work, including all code and chat history. This action cannot be undone.")
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    await loadSelectedPhoto(newItem)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.sheetBackground)
    }
    
    // MARK: - Thumbnail Editor
    
    private var captureDisabled: Bool {
        workEditor.previewWebView == nil || !workEditor.hasCode || workEditor.isCapturingThumbnail
    }
    
    private var thumbnailEditor: some View {
        VStack(spacing: 12) {
            thumbnailPreview
            
            VStack(spacing: 8) {
                Button {
                    Task {
                        await workEditor.captureThumbnail()
                    }
                } label: {
                    Label("Capture from Preview", systemImage: "camera.viewfinder")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(captureDisabled ? Color.secondaryBackground.opacity(0.5) : Color.brand.opacity(0.2))
                        .foregroundColor(captureDisabled ? Color.secondary : Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(captureDisabled)
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Upload from Photos", systemImage: "photo.on.rectangle")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondaryBackground)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            
            if captureDisabled && !workEditor.isCapturingThumbnail {
                Text("Visit Preview tab first to enable capture")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            
            if workEditor.hasThumbnail {
                Button(role: .destructive) {
                    workEditor.removeThumbnail()
                } label: {
                    Text("Remove Thumbnail")
                        .font(.system(size: 13))
                }
            }
        }
        .listRowBackground(Color.secondaryBackground.opacity(0.5))
    }
    
    @ViewBuilder
    private var thumbnailPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondaryBackground.opacity(0.5))
            
            if let image = workEditor.thumbnailImage {
                // Local image (not yet uploaded)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let url = workEditor.smallThumbnailURL {
                // Remote cached image
                CachedThumbnail(url: url) {
                    thumbnailPlaceholder
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                thumbnailPlaceholder
            }
            
            if workEditor.isCapturingThumbnail {
                Color.black.opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                ProgressView()
                    .tint(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var thumbnailPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No thumbnail")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                workEditor.setThumbnail(image: image)
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
        
        selectedPhoto = nil
    }
    
    // MARK: - AI Model Picker
    
    private var modelPicker: some View {
        Picker("Model", selection: $chatViewModel.selectedModel) {
            ForEach(AIModel.allCases) { model in
                Text(model.displayName).tag(model)
            }
        }
        .pickerStyle(.menu)
        .listRowBackground(Color.secondaryBackground.opacity(0.5))
    }
    
    // MARK: - Context Window
    
    private var contextWindowView: some View {
        VStack(spacing: 12) {
            // Progress bar with segments
            GeometryReader { geo in
                let usedWidth = geo.size.width * min(chatViewModel.usagePercentage, 1.0)
                let bufferStart = geo.size.width * (Double(ChatViewModel.usableLimit) / Double(ChatViewModel.contextLimit))
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground)
                    
                    // Buffer zone indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground.opacity(0.5))
                        .frame(width: geo.size.width - bufferStart)
                        .offset(x: bufferStart)
                    
                    // Used portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(contextColor(for: chatViewModel.usagePercentage))
                        .frame(width: max(usedWidth, 0))
                }
            }
            .frame(height: 8)
            
            // Stats grid
            HStack(spacing: 0) {
                statItem(
                    label: "Used",
                    value: formatTokens(chatViewModel.promptTokens),
                    color: contextColor(for: chatViewModel.usagePercentage)
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.border)
                
                statItem(
                    label: "Available",
                    value: formatTokens(ChatViewModel.usableLimit - chatViewModel.promptTokens),
                    color: .primary
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.border)
                
                statItem(
                    label: "Buffer",
                    value: formatTokens(ChatViewModel.bufferSize),
                    color: .secondary
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.border)
                
                statItem(
                    label: "Total",
                    value: "128K",
                    color: .secondary
                )
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.secondaryBackground.opacity(0.5))
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func contextColor(for percentage: Double) -> Color {
        if percentage >= 0.8 { return .red }
        if percentage >= 0.6 { return .orange }
        return .green
    }
    
    private func formatTokens(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.0fK", Double(count) / 1000)
        }
        return "\(count)"
    }
    
    // MARK: - Visibility
    
    private var visibilityPicker: some View {
        Toggle(isOn: $workEditor.isPublished) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workEditor.isPublished ? "Published" : "Draft")
                    .font(.system(size: 16, weight: .medium))
                Text(workEditor.isPublished ? "Everyone can see this work" : "Only you can see this work")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.green)
        .listRowBackground(Color.secondaryBackground.opacity(0.5))
    }
    
    // MARK: - Tags
    
    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Add tag...", text: $tagInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(addTag)
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(tagInput.isEmpty ? Color.secondary : Color.brand)
                }
                .disabled(tagInput.isEmpty)
            }
            
            if !workEditor.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(workEditor.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            workEditor.tags.removeAll { $0 == tag }
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.secondaryBackground.opacity(0.5))
    }
    
    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !workEditor.tags.contains(tag) else { return }
        workEditor.tags.append(tag)
        tagInput = ""
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brand.opacity(0.3))
        .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var workEditor = WorkEditorViewModel()
    WorkOptionsSheet(workEditor: workEditor, chatViewModel: ChatViewModel(workEditor: workEditor)) {
        print("Delete tapped")
    }
}

