//
//  ProfileView.swift
//  Swipop
//

import SwiftUI
import Auth

struct ProfileView: View {
    
    @Binding var showLogin: Bool
    private let auth = AuthService.shared
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if auth.isAuthenticated {
                authenticatedContent
            } else {
                signInPrompt
            }
        }
    }
    
    private var authenticatedContent: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(auth.currentUser?.email?.prefix(1).uppercased() ?? "U"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(auth.currentUser?.email ?? "User")
                .font(.title3)
                .foregroundColor(.white)
            
            Button {
                Task { try? await auth.signOut() }
            } label: {
                Text("Sign Out")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Sign in to see your profile")
                .font(.title3)
                .foregroundColor(.white)
            
            Button {
                showLogin = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
            }
        }
    }
}

#Preview {
    ProfileView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}

