//
//  AuthService.swift
//  Swipop
//
//  Authentication service managing user sessions
//

import Foundation
import AuthenticationServices
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
    
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
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

