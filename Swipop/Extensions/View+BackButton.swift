//
//  View+BackButton.swift
//  Swipop
//
//  Minimal back button display mode for NavigationStack
//

import SwiftUI

extension View {
    /// Sets the back button to display only the chevron icon without text
    func minimalBackButton() -> some View {
        self.modifier(MinimalBackButtonModifier())
    }
}

private struct MinimalBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MinimalBackButtonHelper())
    }
}

private struct MinimalBackButtonHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MinimalBackButtonViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class MinimalBackButtonViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.backButtonDisplayMode = .minimal
    }
}

