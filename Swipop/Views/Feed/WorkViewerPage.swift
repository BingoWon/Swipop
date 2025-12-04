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
    
    private let buttonSize: CGFloat = 36
    
    private var actionButtonsGroup: some View {
        HStack(spacing: 0) {
            glassIconButton(interaction.isLiked ? "heart.fill" : "heart", tint: interaction.isLiked ? .red : .white, action: handleLike)
            glassIconButton("bubble.right", action: { showComments = true })
            glassIconButton(interaction.isCollected ? "bookmark.fill" : "bookmark", tint: interaction.isCollected ? .yellow : .white, action: handleCollect)
            glassIconButton("square.and.arrow.up", action: { showShare = true })
        }
        .frame(height: buttonSize)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func glassIconButton(_ icon: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(Rectangle())
        }
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
