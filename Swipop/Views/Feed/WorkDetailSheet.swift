//
//  WorkDetailSheet.swift
//  Swipop
//
//  Full work and creator details sheet
//

import SwiftUI

struct WorkDetailSheet: View {
    
    let work: Work
    @Binding var showLogin: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var isLiked = false
    @State private var isCollected = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Creator section
                    creatorSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Work info
                    workSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Actions
                    actionsSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Stats
                    statsSection
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle(work.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
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
    }
    
    // MARK: - Creator Section
    
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
            
            Button {
                requireLogin {}
            } label: {
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
    
    // MARK: - Work Section
    
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
            
            // Tags (placeholder)
            HStack(spacing: 8) {
                ForEach(["#creative", "#webdev", "#animation"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a855f7"))
                }
            }
            .padding(.top, 4)
            
            // Time
            Text("2 hours ago")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 4)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: 0) {
            ActionTile(icon: isLiked ? "heart.fill" : "heart", label: "Like", tint: isLiked ? .red : .white) {
                requireLogin {
                    isLiked.toggle()
                }
            }
            
            ActionTile(icon: "bubble.right", label: "Comment", tint: .white) {
                requireLogin {}
            }
            
            ActionTile(icon: isCollected ? "bookmark.fill" : "bookmark", label: "Save", tint: isCollected ? .yellow : .white) {
                requireLogin {
                    isCollected.toggle()
                }
            }
            
            ActionTile(icon: "arrowshape.turn.up.forward", label: "Share", tint: .white) {
                // Share
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 32) {
            StatItem(value: work.viewCount, label: "Views")
            StatItem(value: work.likeCount, label: "Likes")
            StatItem(value: work.commentCount, label: "Comments")
            StatItem(value: work.shareCount, label: "Shares")
        }
    }
    
    // MARK: - Helpers
    
    private func requireLogin(action: @escaping () -> Void) {
        if authService.isAuthenticated {
            action()
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLogin = true
            }
        }
    }
}

// MARK: - Action Tile

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

// MARK: - Stat Item

private struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatCount(value))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

#Preview {
    WorkDetailSheet(work: .sample, showLogin: .constant(false))
}

