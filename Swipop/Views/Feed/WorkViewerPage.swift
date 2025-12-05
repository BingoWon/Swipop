//
//  WorkViewerPage.swift
//  Swipop
//
//  Full-screen work viewer with platform-specific UI
//  - iOS 26: Native toolbar + Liquid Glass bottom accessory
//  - iOS 18: Custom glass top bar + Material bottom accessory
//

import SwiftUI

struct WorkViewerPage: View {
    let initialWork: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showComments = false
    @State private var showShare = false
    @State private var showDetail = false
    
    private let feed = FeedViewModel.shared
    
    init(work: Work, showLogin: Binding<Bool>) {
        self.initialWork = work
        self._showLogin = showLogin
    }
    
    private var currentWork: Work {
        feed.currentWork ?? initialWork
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WorkWebView(work: currentWork)
                .id(feed.currentIndex)
                .ignoresSafeArea()
            
            FloatingWorkAccessory(showDetail: $showDetail)
        }
        .toolbar(.hidden, for: .tabBar)
        .modifier(PlatformNavigationModifier(
            dismiss: dismiss,
            workId: currentWork.id,
            showComments: $showComments,
            showShare: $showShare,
            onLike: handleLike,
            onCollect: handleCollect
        ))
        .sheet(isPresented: $showComments) {
            CommentSheet(work: currentWork, showLogin: $showLogin)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(work: currentWork)
        }
        .sheet(isPresented: $showDetail) {
            WorkDetailSheet(work: currentWork, showLogin: $showLogin)
        }
        .onAppear {
            feed.setCurrentWork(initialWork)
        }
    }
    
    // MARK: - Actions
    
    private func handleLike() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await InteractionStore.shared.toggleLike(workId: currentWork.id) }
    }
    
    private func handleCollect() {
        guard AuthService.shared.isAuthenticated else {
            showLogin = true
            return
        }
        Task { await InteractionStore.shared.toggleCollect(workId: currentWork.id) }
    }
}

// MARK: - Platform Navigation Modifier

private struct PlatformNavigationModifier: ViewModifier {
    let dismiss: DismissAction
    let workId: UUID
    @Binding var showComments: Bool
    @Binding var showShare: Bool
    let onLike: () -> Void
    let onCollect: () -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbar { iOS26ToolbarContent(workId: workId, showComments: $showComments, showShare: $showShare, onLike: onLike, onCollect: onCollect) }
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
                .background(SwipeBackEnabler())
                .safeAreaInset(edge: .top) {
                    iOS18TopBar(dismiss: dismiss, workId: workId, showComments: $showComments, showShare: $showShare, onLike: onLike, onCollect: onCollect)
                }
        }
    }
}

// MARK: - iOS 26 Toolbar Content

@available(iOS 26.0, *)
private struct iOS26ToolbarContent: ToolbarContent {
    let workId: UUID
    @Binding var showComments: Bool
    @Binding var showShare: Bool
    let onLike: () -> Void
    let onCollect: () -> Void
    
    private let store = InteractionStore.shared
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: onLike) {
                Image(systemName: store.isLiked(workId) ? "heart.fill" : "heart")
            }
            .tint(store.isLiked(workId) ? .red : .primary)
            
            Button { showComments = true } label: {
                Image(systemName: "bubble.right")
            }
            
            Button(action: onCollect) {
                Image(systemName: store.isCollected(workId) ? "bookmark.fill" : "bookmark")
            }
            .tint(store.isCollected(workId) ? .yellow : .primary)
            
            Button { showShare = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - iOS 18 Custom Top Bar

private struct iOS18TopBar: View {
    let dismiss: DismissAction
    let workId: UUID
    @Binding var showComments: Bool
    @Binding var showShare: Bool
    let onLike: () -> Void
    let onCollect: () -> Void
    
    private let store = InteractionStore.shared
    private let buttonWidth: CGFloat = 48
    private let buttonHeight: CGFloat = 44
    private let iconSize: CGFloat = 20
    
    var body: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: buttonHeight, height: buttonHeight)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                glassIconButton(store.isLiked(workId) ? "heart.fill" : "heart", tint: store.isLiked(workId) ? .red : .white, action: onLike)
                glassIconButton("bubble.right", action: { showComments = true })
                glassIconButton(store.isCollected(workId) ? "bookmark.fill" : "bookmark", tint: store.isCollected(workId) ? .yellow : .white, action: onCollect)
                glassIconButton("square.and.arrow.up", action: { showShare = true })
            }
            .frame(height: buttonHeight)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
    }
    
    private func glassIconButton(_ icon: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: buttonWidth, height: buttonHeight)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Swipe Back Enabler (iOS 18 only, restores edge swipe after hiding navigation bar)

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
