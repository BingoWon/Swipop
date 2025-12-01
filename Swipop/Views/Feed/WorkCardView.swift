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
        ZStack {
            // Work content - true full screen
            WorkWebView(work: work)
            
            // Right side action buttons
            VStack {
                Spacer()
                actionButtons
                Spacer()
                    .frame(height: 160)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 12)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Action Buttons (Right Side)
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // Creator avatar with follow button (TikTok style)
            Button {
                // View creator profile
            } label: {
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(Color(hex: "a855f7"))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("C")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    // Red plus button
                    Circle()
                        .fill(.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(y: 10)
                }
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
