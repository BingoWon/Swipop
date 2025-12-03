//
//  WorkSettingsSheet.swift
//  Swipop
//
//  Sheet for editing work metadata and visibility
//

import SwiftUI

struct WorkSettingsSheet: View {
    @Bindable var workEditor: WorkEditorViewModel
    var chatViewModel: ChatViewModel?
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var tagInput = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
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
            .background(Color.darkBackground)
            .navigationTitle("Work Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.darkSheet)
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
                        .fill(Color.white.opacity(0.1))
                    
                    // Buffer zone indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
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
                    .background(Color.white.opacity(0.2))
                
                statItem(
                    label: "Available",
                    value: formatTokens(ChatViewModel.usableLimit - chat.promptTokens),
                    color: .white
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.white.opacity(0.2))
                
                statItem(
                    label: "Buffer",
                    value: formatTokens(ChatViewModel.bufferSize),
                    color: .white.opacity(0.5)
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.white.opacity(0.2))
                
                statItem(
                    label: "Total",
                    value: "128K",
                    color: .white.opacity(0.5)
                )
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.white.opacity(0.05))
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
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
                    .foregroundStyle(isSelected ? color : .white.opacity(0.4))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? color : .white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
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
                        .foregroundStyle(tagInput.isEmpty ? .white.opacity(0.3) : Color.brand)
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
        .listRowBackground(Color.white.opacity(0.05))
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
    .preferredColorScheme(.dark)
}
