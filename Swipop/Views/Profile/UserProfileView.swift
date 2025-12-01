//
//  UserProfileView.swift
//  Swipop
//
//  View other user's profile
//

import SwiftUI

struct UserProfileView: View {
    
    let userId: UUID
    @Binding var showLogin: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ProfileContentView(userId: userId, showLogin: $showLogin)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID(), showLogin: .constant(false))
    }
    .preferredColorScheme(.dark)
}

