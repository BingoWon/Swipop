//
//  MainTabView.swift
//  Swipop
//
//  Main tab container - accessible without login
//

import SwiftUI
import Auth

struct MainTabView: View {
    
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed
            FeedView(showLogin: $showLogin)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Discover
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            // Create - requires login
            CreatePlaceholder(showLogin: $showLogin)
                .tabItem {
                    Label("Create", systemImage: "plus.square.fill")
                }
                .tag(2)
            
            // Profile
            ProfileView(showLogin: $showLogin)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.white)
    }
}

// MARK: - Discover View

struct DiscoverView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Discover")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}

// MARK: - Create Placeholder

struct CreatePlaceholder: View {
    
    @Binding var showLogin: Bool
    @State private var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if authService.isAuthenticated {
                CreateView()
            } else {
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
    }
}

// MARK: - Create View

struct CreateView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Create")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    
    @Binding var showLogin: Bool
    @State private var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if authService.isAuthenticated {
                // Logged in profile
                VStack(spacing: 24) {
                    Circle()
                        .fill(Color(hex: "a855f7"))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(authService.currentUser?.email?.prefix(1).uppercased() ?? "U"))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(authService.currentUser?.email ?? "User")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Button {
                        Task {
                            try? await authService.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            } else {
                // Not logged in
                VStack(spacing: 24) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Sign in to see your profile")
                        .font(.title3)
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
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
