//
//  SwipopApp.swift
//  Swipop
//
//  Created by Bin Wang on 12/1/25.
//

import SwiftUI
import GoogleSignIn

@main
struct SwipopApp: App {
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
