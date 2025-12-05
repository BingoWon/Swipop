//
//  SwipopApp.swift
//  Swipop
//

import SwiftUI
import GoogleSignIn

@main
struct SwipopApp: App {
    @State private var appearance = AppearanceSettings.shared
    
    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Secrets.googleIOSClientID)
        ThumbnailCache.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
                .environment(appearance)
                .onOpenURL { url in
                    // Handle Google Sign-In callback
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    
                    // Handle Supabase OAuth callback (GitHub)
                    if url.scheme == "swipop" {
                        Task {
                            try? await AuthService.shared.handleOAuthCallback(url)
                        }
                    }
                }
        }
    }
}
