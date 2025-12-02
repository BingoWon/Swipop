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
                    Divider().background(Color.white.opacity(0.2))
                    workSection
                    Divider().background(Color.white.opacity(0.2))
                    actionsSection
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
            // Views (display only)
            StatActionTile(
                icon: "eye",
                count: work.viewCount,
                tint: .white
            )
            
            // Like
            StatActionTile(
                icon: interaction.isLiked ? "heart.fill" : "heart",
                count: interaction.likeCount,
                tint: interaction.isLiked ? .red : .white
            ) {
                requireLogin {
                    Task { await interaction.toggleLike() }
                }
            }
            
            // Comment
            StatActionTile(
                icon: "bubble.right",
                count: work.commentCount,
                tint: .white
            ) {
                showComments = true
            }
            
            // Collect
            StatActionTile(
                icon: interaction.isCollected ? "bookmark.fill" : "bookmark",
                count: interaction.collectCount,
                tint: interaction.isCollected ? .yellow : .white
            ) {
                requireLogin {
                    Task { await interaction.toggleCollect() }
                }
            }
            
            // Share
            StatActionTile(
                icon: "square.and.arrow.up",
                count: work.shareCount,
                tint: .white
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
                    .foregroundStyle(Color(hex: "a855f7"))
                Text("Source Code")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
    var tint: Color = .white
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
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

#Preview {
    WorkDetailSheet(work: .sample, showLogin: .constant(false))
}
