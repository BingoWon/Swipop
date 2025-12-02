//
//  WorkDetailSheet.swift
//  Swipop
//

import SwiftUI

struct WorkDetailSheet: View {
    
    enum CodeType: String, CaseIterable {
        case html = "HTML"
        case css = "CSS"
        case js = "JS"
    }
    
    let work: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var interaction: InteractionViewModel
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var selectedCodeType: CodeType = .html
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.work = work
        self._showLogin = showLogin
        self._interaction = State(initialValue: InteractionViewModel(work: work))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    creatorSection
                    Divider().background(Color.white.opacity(0.2))
                    workSection
                    Divider().background(Color.white.opacity(0.2))
                    actionsSection
                    Divider().background(Color.white.opacity(0.2))
                    statsSection
                    Divider().background(Color.white.opacity(0.2))
                    sourceCodeSection
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle(work.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
        .task {
            await interaction.loadState()
        }
        .sheet(isPresented: $showComments) {
            CommentSheet(work: work, showLogin: $showLogin)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(work: work)
        }
    }
    
    // MARK: - Sections
    
    private var creatorSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 56, height: 56)
                .overlay(
                    Text("C")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("@creator")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Creative Developer")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button { requireLogin {} } label: {
                Text("Follow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(hex: "a855f7"))
                    .cornerRadius(20)
            }
        }
    }
    
    private var workSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(work.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if let description = work.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            
            HStack(spacing: 8) {
                ForEach(["#creative", "#webdev", "#animation"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a855f7"))
                }
            }
            .padding(.top, 4)
            
            Text("2 hours ago")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 4)
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 0) {
            ActionTile(
                icon: "heart.fill",
                label: "Like",
                tint: interaction.isLiked ? .red : .white
            ) {
                requireLogin {
                    Task { await interaction.toggleLike() }
                }
            }
            
            ActionTile(icon: "bubble.right.fill", label: "Comment") {
                showComments = true
            }
            
            ActionTile(
                icon: "bookmark.fill",
                label: "Save",
                tint: interaction.isCollected ? .yellow : .white
            ) {
                requireLogin {
                    Task { await interaction.toggleCollect() }
                }
            }
            
            ActionTile(icon: "arrowshape.turn.up.forward.fill", label: "Share") {
                showShareSheet = true
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 32) {
            StatItem(value: work.viewCount, label: "Views")
            StatItem(value: interaction.likeCount, label: "Likes")
            StatItem(value: work.commentCount, label: "Comments")
            StatItem(value: work.shareCount, label: "Shares")
        }
    }
    
    private var sourceCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(Color(hex: "a855f7"))
                Text("Source Code")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Segmented Picker
            Picker("Code Type", selection: $selectedCodeType) {
                ForEach(CodeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Code Content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(currentCode)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(codeColor)
                    .padding(16)
                    .frame(minWidth: 300, alignment: .topLeading)
            }
            .frame(height: 200)
            .background(Color(hex: "1a1a2e"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var currentCode: String {
        switch selectedCodeType {
        case .html: work.htmlContent ?? "// No HTML content"
        case .css: work.cssContent ?? "/* No CSS content */"
        case .js: work.jsContent ?? "// No JavaScript content"
        }
    }
    
    private var codeColor: Color {
        switch selectedCodeType {
        case .html: Color(hex: "f97316")  // Orange
        case .css: Color(hex: "3b82f6")   // Blue
        case .js: Color(hex: "eab308")    // Yellow
        }
    }
    
    // MARK: - Helpers
    
    private func requireLogin(action: @escaping () -> Void) {
        if AuthService.shared.isAuthenticated {
            action()
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLogin = true
            }
        }
    }
}

// MARK: - Supporting Views

private struct ActionTile: View {
    let icon: String
    let label: String
    var tint: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(tint)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value.formatted)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    WorkDetailSheet(work: .sample, showLogin: .constant(false))
}
