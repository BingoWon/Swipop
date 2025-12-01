//
//  WorkCardView.swift
//  Swipop
//
//  Full-screen work card with WebView and action buttons
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @Binding var showLogin: Bool
    var onPrevious: () -> Void
    var onNext: () -> Void
    
    @State private var authService = AuthService.shared
    @State private var isLiked = false
    @State private var isCollected = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Work content - true full screen
            WorkWebView(work: work)
            
            // Bottom gradient for readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            // Right side action buttons - vertically centered
            VStack {
                Spacer()
                actionButtons
                Spacer()
                    .frame(height: 150)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 12)
            
            // Bottom left - creator info
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                workInfo
                    .padding(.leading, 16)
                    .padding(.bottom, 120)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Work Info (Bottom Left)
    
    private var workInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Creator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "a855f7"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("C")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text("@creator")
                    .font(.system(size: 16, weight: .semibold))
                
                Button {
                    requireLogin {}
                } label: {
                    Text("Follow")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            // Title
            Text(work.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            
            // Description
            if let description = work.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: 280, alignment: .leading)
    }
    
    // MARK: - Action Buttons (Right Side)
    
    private var actionButtons: some View {
        VStack(spacing: 24) {
            // Creator avatar
            Button {
                // View profile
            } label: {
                Circle()
                    .fill(Color(hex: "a855f7"))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text("C")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .fill(.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(y: 24)
                    )
            }
            .padding(.bottom, 8)
            
            // Like
            ActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: work.likeCount,
                tint: isLiked ? .red : .white
            ) {
                handleLike()
            }
            
            // Comment
            ActionButton(icon: "bubble.right.fill", count: work.commentCount) {
                requireLogin {
                    // Open comments
                }
            }
            
            // Collect
            ActionButton(
                icon: isCollected ? "bookmark.fill" : "bookmark",
                count: nil,
                tint: isCollected ? .yellow : .white
            ) {
                handleCollect()
            }
            
            // Share
            ActionButton(icon: "arrowshape.turn.up.forward.fill", count: work.shareCount) {
                // Share
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleLike() {
        requireLogin {
            withAnimation(.spring(response: 0.3)) {
                isLiked.toggle()
            }
        }
    }
    
    private func handleCollect() {
        requireLogin {
            withAnimation(.spring(response: 0.3)) {
                isCollected.toggle()
            }
        }
    }
    
    private func requireLogin(action: @escaping () -> Void) {
        if authService.isAuthenticated {
            action()
        } else {
            showLogin = true
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let count: Int?
    var tint: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(tint)
                
                if let count = count {
                    Text(formatCount(count))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
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
    WorkCardView(
        work: .sample,
        showLogin: .constant(false),
        onPrevious: {},
        onNext: {}
    )
    .preferredColorScheme(.dark)
}
