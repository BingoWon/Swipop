//
//  ModelPickerSheet.swift
//  Swipop
//

import SwiftUI

struct ModelPickerSheet: View {
    @Binding var selectedModel: AIModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            VStack(spacing: 12) {
                ForEach(AIModel.allCases) { model in
                    ModelRow(model: model, isSelected: selectedModel == model) {
                        selectedModel = model
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Select Model")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

private struct ModelRow: View {
    let model: AIModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(isSelected ? .brandGradient : LinearGradient(colors: [.white.opacity(0.15)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: model.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text(model.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.brand.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brand.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
