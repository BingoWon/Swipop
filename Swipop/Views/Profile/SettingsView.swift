//
//  SettingsView.swift
//  Swipop
//

import SwiftUI
import Auth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceSettings.self) private var appearance
    @State private var showLogoutConfirm = false
    
    private let auth = AuthService.shared
    
    var body: some View {
        @Bindable var appearance = appearance
        
        NavigationStack {
            List {
                // Appearance Section
                Section("Appearance") {
                    Picker(selection: $appearance.mode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "lock")
                    }
                }
                
                // About Section
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Swipop", systemImage: "info.circle")
                    }
                    
                    Link(destination: URL(string: "https://swipop.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Link(destination: URL(string: "https://swipop.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await auth.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    var body: some View {
        List {
            Section("Email") {
                Text(AuthService.shared.currentUser?.email ?? "Not set")
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Account")
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @State private var likesEnabled = true
    @State private var commentsEnabled = true
    @State private var followsEnabled = true
    
    var body: some View {
        List {
            Section {
                Toggle("Likes", isOn: $likesEnabled)
                Toggle("Comments", isOn: $commentsEnabled)
                Toggle("New Followers", isOn: $followsEnabled)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Notifications")
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @State private var privateAccount = false
    
    var body: some View {
        List {
            Section {
                Toggle("Private Account", isOn: $privateAccount)
            } footer: {
                Text("When enabled, only approved followers can see your works.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Privacy")
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Text("Swipop is a platform for discovering and sharing creative frontend works. Built with SwiftUI and Supabase.")
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceSettings.shared)
}
