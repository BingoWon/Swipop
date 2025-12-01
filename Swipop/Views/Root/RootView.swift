//
//  RootView.swift
//  Swipop
//
//  Root view - users can browse without login
//

import SwiftUI

struct RootView: View {
    
    @State private var showLogin = false
    
    var body: some View {
        MainTabView(showLogin: $showLogin)
            .sheet(isPresented: $showLogin) {
                LoginView(isPresented: $showLogin)
            }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
