//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @Binding var showLogin: Bool
    
    @State private var isLiked = false
    @State private var isCollected = false
    
    var body: some View {
        ZStack {
            WorkWebView(work: work)
            
            // Right side actions
            VStack {
                Spacer()
                actionButtons
                Spacer().frame(height: 160)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 12)
        }
        .ignoresSafeArea()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // Creator avatar + follow
            Button {} label: {
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(Color(hex: "a855f7"))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("C")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
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
                requireLogin { isLiked.toggle() }
            }
            
            // Comment
            ActionButton(icon: "bubble.right.fill", count: work.commentCount) {
                requireLogin {}
            }
            
            // Collect
            ActionButton(
                icon: isCollected ? "bookmark.fill" : "bookmark",
                tint: isCollected ? .yellow : .white
            ) {
                requireLogin { isCollected.toggle() }
            }
            
            // Share
            ActionButton(icon: "arrowshape.turn.up.forward.fill", count: work.shareCount) {}
        }
    }
    
    private func requireLogin(action: @escaping () -> Void) {
        if AuthService.shared.isAuthenticated {
            withAnimation(.spring(response: 0.3)) { action() }
        } else {
            showLogin = true
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    
    let icon: String
    var count: Int? = nil
    var tint: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(tint)
                
                if let count {
                    Text(count.formatted)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    WorkCardView(work: .sample, showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
