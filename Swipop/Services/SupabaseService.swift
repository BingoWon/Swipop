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
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    flowType: .pkce,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
