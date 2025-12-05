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
                // Appearance
                Section {
                    Picker(selection: $appearance.mode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("Appearance", systemImage: "paintbrush.pointed")
                }
                
                // Account
                Section {
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "lock")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("Account", systemImage: "person")
                }
                
                // About
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Swipop", systemImage: "info.circle")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                    
                    Link(destination: URL(string: "https://swipop.app/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                    
                    Link(destination: URL(string: "https://swipop.app/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("About", systemImage: "info.circle")
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
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
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
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
        .glassSheetBackground()
        .preferredColorScheme(appearance.colorScheme)
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(AuthService.shared.currentUser?.email ?? "Not set")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("Email", systemImage: "envelope")
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
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                Toggle("Comments", isOn: $commentsEnabled)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                Toggle("New Followers", isOn: $followsEnabled)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("Push Notifications", systemImage: "bell.badge")
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
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("Account Visibility", systemImage: "eye")
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
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("App Info", systemImage: "app.badge")
            }
            
            Section {
                Text("Swipop is a platform for discovering and sharing creative frontend works. Built with SwiftUI and Supabase.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
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
