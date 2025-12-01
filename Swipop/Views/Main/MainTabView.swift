//
//  MainTabView.swift
//  Swipop
//
//  Main tab container with iOS 26 liquid glass tab bar
//

import SwiftUI
import Auth

struct MainTabView: View {
    
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed - full screen
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin)
                    .ignoresSafeArea(.all)
            }
            
            // Create - requires login
            Tab("Create", systemImage: "plus.square.fill", value: 1) {
                CreatePlaceholder(showLogin: $showLogin)
            }
            
            // Profile
            Tab("Profile", systemImage: "person.fill", value: 2) {
                ProfileView(showLogin: $showLogin)
            }
            
            // Search - appears as button in bottom right
            Tab("Search", systemImage: "magnifyingglass", value: 3, role: .search) {
                SearchView(searchText: $searchText)
            }
        }
        .tabViewBottomAccessory {
            NavigationControls()
        }
        .tint(.white)
    }
}

// MARK: - Navigation Controls (Bottom Accessory)

struct NavigationControls: View {
    var body: some View {
        HStack(spacing: 0) {
            // Previous work
            Button {
                NotificationCenter.default.post(name: .navigateToPrevious, object: nil)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
                .frame(height: 20)
            
            // Next work
            Button {
                NotificationCenter.default.post(name: .navigateToNext, object: nil)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToPrevious = Notification.Name("navigateToPrevious")
    static let navigateToNext = Notification.Name("navigateToNext")
}

// MARK: - Search View

struct SearchView: View {
    @Binding var searchText: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Search works and creators")
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    Text("Results for: \(searchText)")
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Works, creators...")
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
