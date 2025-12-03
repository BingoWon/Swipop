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
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: Secrets.googleIOSClientID
        )
        
        // Configure thumbnail cache
        ThumbnailCache.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
                .environment(appearance)
        }
    }
}
