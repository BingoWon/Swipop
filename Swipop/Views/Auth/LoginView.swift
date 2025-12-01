//
//  LoginView.swift
//  Swipop
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @Binding var isPresented: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let auth = AuthService.shared
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(hex: "1a1a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Logo
                VStack(spacing: 16) {
                    Text("Swipop")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "a855f7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Sign in to like, collect, and create")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: 16) {
                    appleSignInButton
                    googleSignInButton
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                Text("By continuing, you agree to our Terms of Service")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 32)
            }
            
            if auth.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated { isPresented = false }
        }
    }
    
    // MARK: - Apple Sign In
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            Task { await handleAppleSignIn(result) }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 54)
        .cornerRadius(12)
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await auth.signInWithApple(credential: credential)
                } catch {
                    displayError(error)
                }
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                displayError(error)
            }
        }
    }
    
    // MARK: - Google Sign In
    
    private var googleSignInButton: some View {
        Button {
            Task { await handleGoogleSignIn() }
        } label: {
            HStack(spacing: 12) {
                GoogleLogo().frame(width: 20, height: 20)
                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await auth.signInWithGoogle()
        } catch {
            if (error as NSError).code != -5 {
                displayError(error)
            }
        }
    }
    
    private func displayError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Google Logo

private struct GoogleLogo: View {
    var body: some View {
        ZStack {
            Circle().trim(from: 0.0, to: 0.25).stroke(Color(hex: "4285F4"), lineWidth: 3)
            Circle().trim(from: 0.25, to: 0.5).stroke(Color(hex: "34A853"), lineWidth: 3)
            Circle().trim(from: 0.5, to: 0.75).stroke(Color(hex: "FBBC05"), lineWidth: 3)
            Circle().trim(from: 0.75, to: 1.0).stroke(Color(hex: "EA4335"), lineWidth: 3)
        }
        .rotationEffect(.degrees(-90))
    }
}

#Preview {
    LoginView(isPresented: .constant(true))
}
