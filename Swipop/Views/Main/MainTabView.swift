//
//  MainTabView.swift
//  Swipop
//
//  Main tab container after authentication
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed
            FeedView()
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
            
            // Create
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus.square.fill")
                }
                .tag(2)
            
            // Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.white)
    }
}

// MARK: - Placeholder Views

struct FeedView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Feed")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}

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

struct ProfileView: View {
    
    @State private var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Profile")
                    .foregroundColor(.white)
                    .font(.title)
                
                Button("Sign Out") {
                    Task {
                        try? await authService.signOut()
                    }
                }
                .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    MainTabView()
}

