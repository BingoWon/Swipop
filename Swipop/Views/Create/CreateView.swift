//
//  CreateView.swift
//  Swipop
//

import SwiftUI

struct CreateView: View {
    
    @Binding var showLogin: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if AuthService.shared.isAuthenticated {
                // TODO: Implement editor
                Text("Create")
                    .foregroundColor(.white)
                    .font(.title)
            } else {
                signInPrompt
            }
        }
    }
    
    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Sign in to create")
                .font(.title2)
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
    CreateView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}

