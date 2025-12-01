//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @Binding var showLogin: Bool
    
    @State private var interaction: InteractionViewModel
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var triggerLikeAnimation = false
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.work = work
        self._showLogin = showLogin
        self._interaction = State(initialValue: InteractionViewModel(work: work))
    }
    
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
            
            // Double-tap to like
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    doubleTapLike()
                }
            
            // Like animation overlay
            if triggerLikeAnimation {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
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
    
    // MARK: - Action Buttons
    
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
                icon: interaction.isLiked ? "heart.fill" : "heart",
                count: interaction.likeCount,
                tint: interaction.isLiked ? .red : .white
            ) {
                handleLike()
            }
            
            // Comment
            ActionButton(icon: "bubble.right.fill", count: work.commentCount) {
                showComments = true
            }
            
            // Collect
            ActionButton(
                icon: interaction.isCollected ? "bookmark.fill" : "bookmark",
                tint: interaction.isCollected ? .yellow : .white
            ) {
                handleCollect()
            }
            
            // Share
            ActionButton(icon: "arrowshape.turn.up.forward.fill", count: work.shareCount) {
                showShareSheet = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        withAnimation(.spring(response: 0.3)) {
            Task { await interaction.toggleLike() }
        }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        withAnimation(.spring(response: 0.3)) {
            Task { await interaction.toggleCollect() }
        }
    }
    
    private func doubleTapLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        
        // Only like, don't unlike on double-tap
        if !interaction.isLiked {
            Task { await interaction.toggleLike() }
        }
        
        // Show animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            triggerLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                triggerLikeAnimation = false
            }
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    
    let work: Work
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "\(work.title) on Swipop"
        // TODO: Generate actual share URL
        let url = URL(string: "https://swipop.app/work/\(work.id)")!
        
        return UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    WorkCardView(work: .sample, showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
