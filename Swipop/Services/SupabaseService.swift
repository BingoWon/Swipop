//
//  SupabaseService.swift
//  Swipop
//
//  Supabase client singleton
//

import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    
    static let redirectURL = URL(string: "swipop://auth/callback")!
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: Self.redirectURL,
                    flowType: .pkce,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
