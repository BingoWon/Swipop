//
//  WorkViewerPage.swift
//  Swipop
//
//  Full-screen work viewer with native navigation
//

import SwiftUI

struct WorkViewerPage: View {
    let initialWork: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var interaction: InteractionViewModel
    @State private var showComments = false
    @State private var showShare = false
    @State private var showDetail = false
    
    private let feed = FeedViewModel.shared
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.initialWork = work
        self._showLogin = showLogin
        self._interaction = State(initialValue: InteractionViewModel(work: work))
    }
    
    private var currentWork: Work {
        feed.currentWork ?? initialWork
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WorkWebView(work: currentWork)
                .id(feed.currentIndex)
                .ignoresSafeArea()
            
            // iOS 18: floating accessory | iOS 26: uses native tabViewBottomAccessory
            if #unavailable(iOS 26.0) {
                FloatingWorkAccessory(showDetail: $showDetail)
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(SwipeBackEnabler())
        .sheet(isPresented: $showComments) {
            CommentSheet(work: currentWork, showLogin: $showLogin)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(work: currentWork)
        }
        .sheet(isPresented: $showDetail) {
            WorkDetailSheet(work: currentWork, showLogin: $showLogin)
        }
        .onChange(of: feed.currentWork?.id) { _, _ in
            reloadInteraction()
        }
        .onAppear {
            feed.setCurrentWork(initialWork)
            reloadInteraction()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Back button
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            
            Spacer()
            
            // Action buttons group
            actionButtonsGroup
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var actionButtonsGroup: some View {
        HStack(spacing: 2) {
            GlassActionButton(
                icon: interaction.isLiked ? "heart.fill" : "heart",
                count: interaction.likeCount,
                tint: interaction.isLiked ? .red : .white,
                action: handleLike
            )
            
            GlassActionButton(
                icon: "bubble.right",
                count: currentWork.commentCount,
                tint: .white
            ) {
                showComments = true
            }
            
            GlassActionButton(
                icon: interaction.isCollected ? "bookmark.fill" : "bookmark",
                count: interaction.collectCount,
                tint: interaction.isCollected ? .yellow : .white,
                action: handleCollect
            )
            
            GlassActionButton(
                icon: "square.and.arrow.up",
                tint: .white
            ) {
                showShare = true
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    // MARK: - Actions
    
    private func reloadInteraction() {
        interaction = InteractionViewModel(work: currentWork)
        Task { await interaction.loadState() }
    }
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction.toggleLike() }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await interaction.toggleCollect() }
    }
}

// MARK: - Glass Action Button

private struct GlassActionButton: View {
    let icon: String
    var count: Int? = nil
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Swipe Back Enabler

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackEnablerController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class SwipeBackEnablerController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let navigationController = navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = self
        }
    }
}

extension SwipeBackEnablerController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}

#Preview {
    NavigationStack {
        WorkViewerPage(work: .sample, showLogin: .constant(false))
    }
}
