//
//  AuthService.swift
//  Swipop
//
//  Authentication service with Email, GitHub, Apple, and Google providers
//

import Foundation
import AuthenticationServices
import GoogleSignIn
import Supabase

// MARK: - Sign Up Result

enum SignUpResult {
    case success
    case confirmationRequired(email: String)
}

// MARK: - Auth Service

@Observable
final class AuthService {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - State
    
    private(set) var currentUser: User?
    private(set) var isLoading = false
    
    var isAuthenticated: Bool { currentUser != nil }
    
    // MARK: - Private
    
    private let supabase = SupabaseService.shared.client
    
    private init() {
        Task { await checkSession() }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            if currentUser != nil {
                await preloadUserData()
            }
        } catch {
            currentUser = nil
        }
    }
    
    @MainActor
    private func preloadUserData() async {
        await CurrentUserProfile.shared.preload()
    }
    
    // MARK: - Email Authentication
    
    @discardableResult
    func signUp(email: String, password: String) async throws -> SignUpResult {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signUp(email: email, password: password)
        
        if response.session != nil {
            currentUser = response.user
            await preloadUserData()
            return .success
        }
        
        return .confirmationRequired(email: email)
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
        await preloadUserData()
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - GitHub OAuth
    
    @MainActor
    func signInWithGitHub() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = try await supabase.auth.getOAuthSignInURL(
            provider: .github,
            redirectTo: SupabaseService.redirectURL
        )
        
        _ = await UIApplication.shared.open(url)
    }
    
    @MainActor
    func handleOAuthCallback(_ url: URL) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let session = try await supabase.auth.session(from: url)
        currentUser = session.user
        await preloadUserData()
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: tokenString)
        )
        
        currentUser = session.user
        await preloadUserData()
    }
    
    // MARK: - Google Sign In
    
    @MainActor
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.signInFailed
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }
        
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        )
        
        currentUser = session.user
        await preloadUserData()
    }
    
    // MARK: - Sign Out
    
    @MainActor
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        GIDSignIn.sharedInstance.signOut()
        try await supabase.auth.signOut()
        currentUser = nil
        CurrentUserProfile.shared.reset()
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case signInFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid authentication credential"
        case .signInFailed: return "Sign in failed. Please try again."
        }
    }
}
