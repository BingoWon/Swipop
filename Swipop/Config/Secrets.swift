//
//  Secrets.swift
//  Swipop
//
//  Configuration secrets
//

import Foundation

enum Secrets {
    // MARK: - Supabase

    static let supabaseURL = URL(string: "https://axzembhfbmavvklsqsjs.supabase.co")!
    // Publishable key (recommended over legacy JWT anon key)
    static let supabaseAnonKey = "sb_publishable_Yy75sNxMvg-7dVB8xtxpfg_o40AXNEo"

    // MARK: - Google OAuth

    static let googleIOSClientID = "643990942728-t9e5b0gtbi7af9qj9ok6v65kvas4l4aj.apps.googleusercontent.com"
}
