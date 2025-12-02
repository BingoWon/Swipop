//
//  WorkSettingsSheet.swift
//  Swipop
//
//  Settings sheet for editing work metadata
//

import SwiftUI

struct WorkSettingsSheet: View {
    @Bindable var workEditor: WorkEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tagInput = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Visibility Section
                Section {
                    visibilityPicker
                } header: {
                    Label("Visibility", systemImage: "eye")
                }
                
                // Metadata Section
                Section {
                    TextField("Title", text: $workEditor.title)
                    
                    TextField("Description", text: $workEditor.description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Label("Details", systemImage: "doc.text")
                }
                
                // Tags Section
                Section {
                    tagsEditor
                } header: {
                    Label("Tags", systemImage: "tag")
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
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.darkSheet)
    }
    
    // MARK: - Visibility Picker
    
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
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tags Editor
    
    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag input
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
            
            // Tags display
            if !workEditor.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(workEditor.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
            
            Button {
                workEditor.tags.removeAll { $0 == tag }
            } label: {
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
    
    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !workEditor.tags.contains(tag) else { return }
        workEditor.tags.append(tag)
        tagInput = ""
    }
}

// MARK: - Flow Layout for Tags

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    WorkSettingsSheet(workEditor: WorkEditorViewModel())
        .preferredColorScheme(.dark)
}

