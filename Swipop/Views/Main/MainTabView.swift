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
    @State private var showWorkDetail = false
    @State private var feedViewModel = FeedViewModel.shared
    
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
            BottomAccessory(
                showWorkDetail: $showWorkDetail,
                feedViewModel: feedViewModel
            )
        }
        .tint(.white)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feedViewModel.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
    }
}

// MARK: - Bottom Accessory

struct BottomAccessory: View {
    
    @Binding var showWorkDetail: Bool
    var feedViewModel: FeedViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Title - tap to show detail
            Button {
                showWorkDetail = true
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "a855f7"))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("C")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(feedViewModel.currentWork?.title ?? "Swipop")
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            }
            
            Divider()
                .frame(height: 20)
            
            // Right: Next work
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feedViewModel.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 60)
            }
        }
        .foregroundStyle(.white)
    }
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
