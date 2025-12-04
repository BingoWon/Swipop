//
//  View+BackButton.swift
//  Swipop
//
//  Custom glass back button with preserved swipe-back gesture
//

import SwiftUI

extension View {
    /// Replaces system back button with a glass-style custom button
    /// while preserving the native edge swipe-back gesture
    func glassBackButton() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlassBackButton()
                }
            }
            .background(SwipeBackEnabler())
    }
}

// MARK: - Glass Back Button

private struct GlassBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
    }
}

// MARK: - Swipe Back Gesture Enabler

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackEnablerController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class SwipeBackEnablerController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Re-enable the interactive pop gesture after hiding back button
        if let navigationController = navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = self
        }
    }
}

extension SwipeBackEnablerController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow swipe back if there's more than one view controller
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}
