//
//  RootView.swift
//  Swipop
//
//  Root view that switches between auth and main content
//

import SwiftUI

struct RootView: View {
    
    @State private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

#Preview {
    RootView()
}

