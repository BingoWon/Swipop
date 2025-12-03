//
//  LoginView.swift
//  Swipop
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var errorAlert: ErrorAlert?
    
    private let auth = AuthService.shared
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color.secondaryBackground)
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
                                colors: [.textPrimary, .brand],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Sign in to like, collect, and create")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 32)
            }
            
            if auth.isLoading {
                Color.appBackground.opacity(0.8).ignoresSafeArea()
                ProgressView().tint(.brand).scaleEffect(1.5)
            }
        }
        .alert(item: $errorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: alert.showSettings
                    ? .default(Text("Open Settings"), action: openSettings)
                    : .default(Text("Try Again")),
                secondaryButton: .cancel(Text("Later"))
            )
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
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
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
                    showError(for: error, provider: .apple)
                }
            }
        case .failure(let error):
            let nsError = error as NSError
            // Ignore user cancellation
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                showError(for: error, provider: .apple)
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
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(colorScheme == .dark ? Color.white : Color.black)
            .cornerRadius(12)
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await auth.signInWithGoogle()
        } catch {
            let nsError = error as NSError
            // Ignore user cancellation (-5)
            if nsError.code != -5 {
                showError(for: error, provider: .google)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private enum Provider { case apple, google }
    
    private func showError(for error: Error, provider: Provider) {
        let nsError = error as NSError
        
        // Map Apple Sign In errors
        if nsError.domain == ASAuthorizationError.errorDomain {
            switch nsError.code {
            case ASAuthorizationError.unknown.rawValue:
                errorAlert = ErrorAlert(
                    title: "Apple ID Required",
                    message: "Please sign in to your Apple ID in Settings to continue.",
                    showSettings: true
                )
            case ASAuthorizationError.invalidResponse.rawValue,
                 ASAuthorizationError.notHandled.rawValue:
                errorAlert = ErrorAlert(
                    title: "Sign In Failed",
                    message: "Apple Sign In is temporarily unavailable. Please try again or use Google Sign In.",
                    showSettings: false
                )
            case ASAuthorizationError.failed.rawValue:
                errorAlert = ErrorAlert(
                    title: "Sign In Failed",
                    message: "Unable to complete sign in. Please check your Apple ID in Settings.",
                    showSettings: true
                )
            default:
                errorAlert = ErrorAlert(
                    title: "Sign In Failed",
                    message: "Something went wrong. Please try again.",
                    showSettings: false
                )
            }
            return
        }
        
        // Generic error for other cases
        let providerName = provider == .apple ? "Apple" : "Google"
        errorAlert = ErrorAlert(
            title: "\(providerName) Sign In Failed",
            message: "Unable to complete sign in. Please check your internet connection and try again.",
            showSettings: false
        )
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Error Alert Model

private struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let showSettings: Bool
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
