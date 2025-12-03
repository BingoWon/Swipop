//
//  SwipopApp.swift
//  Swipop
//

import SwiftUI
import GoogleSignIn

@main
struct SwipopApp: App {
    
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
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
