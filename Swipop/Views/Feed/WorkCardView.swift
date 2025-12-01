//
//  WorkCardView.swift
//  Swipop
//
//  Full-screen work card with WebView and action buttons
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @State private var isLiked = false
    @State private var isCollected = false
    
    var body: some View {
        ZStack {
            // Work content
            WorkWebView(work: work)
                .ignoresSafeArea()
            
            // Overlay gradient for readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()
            
            // UI overlay
            HStack(alignment: .bottom) {
                // Work info
                workInfo
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Work Info
    
    private var workInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("@creator")
                .font(.system(size: 16, weight: .semibold))
            
            Text(work.title)
                .font(.system(size: 14))
                .lineLimit(2)
            
            if let description = work.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: 250, alignment: .leading)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // Navigate up
            ActionButton(icon: "chevron.up", count: nil) {
                // Handle in parent
            }
            
            // Like
            ActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: work.likeCount,
                tint: isLiked ? .red : .white
            ) {
                withAnimation(.spring(response: 0.3)) {
                    isLiked.toggle()
                }
            }
            
            // Collect
            ActionButton(
                icon: isCollected ? "bookmark.fill" : "bookmark",
                count: nil,
                tint: isCollected ? .yellow : .white
            ) {
                withAnimation(.spring(response: 0.3)) {
                    isCollected.toggle()
                }
            }
            
            // Comment
            ActionButton(icon: "bubble.right", count: work.commentCount) {
                // Open comments
            }
            
            // Share
            ActionButton(icon: "arrowshape.turn.up.right", count: work.shareCount) {
                // Share
            }
            
            // Navigate down
            ActionButton(icon: "chevron.down", count: nil) {
                // Handle in parent
            }
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
            VStack(spacing: 4) {
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
    WorkCardView(work: .sample)
        .preferredColorScheme(.dark)
}

