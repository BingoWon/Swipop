//
//  AuthService.swift
//  Swipop
//
//  Authentication service managing user sessions
//

import Foundation
import AuthenticationServices
import GoogleSignIn
import Supabase

@Observable
final class AuthService {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - State
    
    private(set) var currentUser: User?
    private(set) var isLoading = false
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    // MARK: - Private
    
    private let supabase = SupabaseService.shared.client
    
    private init() {
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
        } catch {
            currentUser = nil
        }
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
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
        
        currentUser = session.user
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
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }
        
        let accessToken = result.user.accessToken.tokenString
        
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        
        currentUser = session.user
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        GIDSignIn.sharedInstance.signOut()
        try await supabase.auth.signOut()
        currentUser = nil
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case signInFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credential"
        case .signInFailed:
            return "Sign in failed. Please try again."
        }
    }
}
