//
//  WorkDetailSheet.swift
//  Swipop
//

import SwiftUI

struct WorkDetailSheet: View {
    
    let work: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var interaction: InteractionViewModel
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var selectedLanguage: CodeLanguage = .html
    
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
                    Divider().background(Color.border)
                    workSection
                    Divider().background(Color.border)
                    actionsSection
                    Divider().background(Color.border)
                    sourceCodeSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(work.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
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
                .fill(Color.brand)
                .frame(width: 56, height: 56)
                .overlay(
                    Text("C")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("@creator")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Creative Developer")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button { requireLogin {} } label: {
                Text("Follow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.brand)
                    .cornerRadius(20)
            }
        }
    }
    
    private var workSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(work.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            if let description = work.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            
            HStack(spacing: 8) {
                ForEach(["#creative", "#webdev", "#animation"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(.top, 4)
            
            Text("2 hours ago")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 0) {
            // Views (display only)
            StatActionTile(
                icon: "eye",
                count: work.viewCount,
                tint: .primary
            )
            
            // Like
            StatActionTile(
                icon: interaction.isLiked ? "heart.fill" : "heart",
                count: interaction.likeCount,
                tint: interaction.isLiked ? .red : .primary
            ) {
                requireLogin {
                    Task { await interaction.toggleLike() }
                }
            }
            
            // Comment
            StatActionTile(
                icon: "bubble.right",
                count: work.commentCount,
                tint: .primary
            ) {
                showComments = true
            }
            
            // Collect
            StatActionTile(
                icon: interaction.isCollected ? "bookmark.fill" : "bookmark",
                count: interaction.collectCount,
                tint: interaction.isCollected ? .yellow : .primary
            ) {
                requireLogin {
                    Task { await interaction.toggleCollect() }
                }
            }
            
            // Share
            StatActionTile(
                icon: "square.and.arrow.up",
                count: work.shareCount,
                tint: .primary
            ) {
                showShareSheet = true
            }
        }
    }
    
    private var sourceCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(Color.brand)
                Text("Source Code")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            // Segmented Picker
            Picker("Language", selection: $selectedLanguage) {
                ForEach(CodeLanguage.allCases, id: \.self) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            
            // Runestone Code View
            RunestoneCodeView(language: selectedLanguage, code: currentCode)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        }
    }
    
    private var currentCode: String {
        switch selectedLanguage {
        case .html: work.htmlContent ?? "<!-- No HTML content -->"
        case .css: work.cssContent ?? "/* No CSS content */"
        case .javascript: work.jsContent ?? "// No JavaScript content"
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

private struct StatActionTile: View {
    let icon: String
    let count: Int
    var tint: Color = .primary
    var action: (() -> Void)?
    
    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var content: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
            Text(count.formatted)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WorkDetailSheet(work: .sample, showLogin: .constant(false))
}
