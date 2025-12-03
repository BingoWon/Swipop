//
//  WorkSettingsSheet.swift
//  Swipop
//
//  Sheet for editing work metadata and visibility
//

import SwiftUI
import PhotosUI

struct WorkSettingsSheet: View {
    @Bindable var workEditor: WorkEditorViewModel
    var chatViewModel: ChatViewModel?
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
                    TextField("Title", text: $workEditor.title)
                    TextField("Description", text: $workEditor.description, axis: .vertical)
                        .lineLimit(3...6)
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
                
                // Context Window
                if let chat = chatViewModel {
                    Section {
                        contextWindowView(chat: chat)
                    } header: {
                        Label("Context", systemImage: "brain")
                    } footer: {
                        Text("Auto-summarize is always enabled. When context reaches capacity, conversation will be automatically compacted to continue.")
                            .font(.system(size: 12))
                    }
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
    
    // MARK: - Context Window
    
    private func contextWindowView(chat: ChatViewModel) -> some View {
        VStack(spacing: 12) {
            // Progress bar with segments
            GeometryReader { geo in
                let usedWidth = geo.size.width * min(chat.usagePercentage, 1.0)
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
                        .fill(contextColor(for: chat.usagePercentage))
                        .frame(width: max(usedWidth, 0))
                }
            }
            .frame(height: 8)
            
            // Stats grid
            HStack(spacing: 0) {
                statItem(
                    label: "Used",
                    value: formatTokens(chat.promptTokens),
                    color: contextColor(for: chat.usagePercentage)
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.border)
                
                statItem(
                    label: "Available",
                    value: formatTokens(ChatViewModel.usableLimit - chat.promptTokens),
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
        VStack(spacing: 12) {
            visibilityOption(
                isSelected: !workEditor.isPublished,
                icon: "eye.slash",
                title: "Draft",
                subtitle: "Only you can see this work",
                color: .orange
            ) {
                workEditor.isPublished = false
            }
            
            visibilityOption(
                isSelected: workEditor.isPublished,
                icon: "eye",
                title: "Published",
                subtitle: "Everyone can see this work",
                color: .green
            ) {
                workEditor.isPublished = true
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private func visibilityOption(
        isSelected: Bool,
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? color : Color.secondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? color : Color.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.secondaryBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
    WorkSettingsSheet(workEditor: WorkEditorViewModel(), chatViewModel: nil) {
        print("Delete tapped")
    }
}
