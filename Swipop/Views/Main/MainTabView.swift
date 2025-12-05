//
//  MainTabView.swift
//  Swipop
//
//  Main tab navigation with iOS 26 and iOS 18 variants
//  Create page presented as fullScreenCover for proper isolation
//

import SwiftUI
import Auth

struct MainTabView: View {
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    @State private var showingCreate = false
    @State private var unreadCount = 0
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
        let editor = WorkEditorViewModel()
        self._workEditor = State(initialValue: editor)
        self._chatViewModel = State(initialValue: ChatViewModel(workEditor: editor))
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                iOS26Content
            } else {
                iOS18Content
            }
        }
        .tint(.primary)
        .fullScreenCover(isPresented: $showingCreate) {
            NavigationStack {
                CreateView(
                    showLogin: $showLogin,
                    workEditor: workEditor,
                    chatViewModel: chatViewModel,
                    selectedSubTab: $createSubTab,
                    onBack: closeCreate
                )
            }
            .tint(.primary)
        }
        .task {
            await loadUnreadCount()
        }
    }
    
    // MARK: - iOS 26
    
    @available(iOS 26.0, *)
    private var iOS26Content: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin)
            }
            Tab("Create", systemImage: "wand.and.stars", value: 1) {
                createPlaceholder
            }
            Tab("Inbox", systemImage: "bell.fill", value: 2) {
                InboxView()
            }
            .badge(unreadCount)
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(showLogin: $showLogin, editWork: editWork)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                previousTab = oldValue
                openCreate()
            }
            if newValue == 2 {
                // Refresh unread count when entering inbox
                Task { await loadUnreadCount() }
            }
        }
        .onChange(of: showingCreate) { _, isShowing in
            if !isShowing && selectedTab == 1 {
                selectedTab = previousTab
            }
        }
    }
    
    // MARK: - iOS 18
    
    private var iOS18Content: some View {
        TabView(selection: $selectedTab) {
            FeedView(showLogin: $showLogin)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            createPlaceholder
                .tabItem { Label("Create", systemImage: "wand.and.stars") }
                .tag(1)
            InboxView()
                .tabItem { Label("Inbox", systemImage: "bell.fill") }
                .tag(2)
                .badge(unreadCount)
            ProfileView(showLogin: $showLogin, editWork: editWork)
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                previousTab = oldValue
                openCreate()
            }
            if newValue == 2 {
                Task { await loadUnreadCount() }
            }
        }
        .onChange(of: showingCreate) { _, isShowing in
            if !isShowing && selectedTab == 1 {
                selectedTab = previousTab
            }
        }
    }
    
    // MARK: - Create Placeholder
    
    private var createPlaceholder: some View {
        Color.appBackground
            .ignoresSafeArea()
    }
    
    // MARK: - Actions
    
    private func openCreate() {
        showingCreate = true
    }
    
    private func closeCreate() {
        Task {
            await workEditor.saveAndReset()
            chatViewModel.clear()
            createSubTab = .chat
        }
        showingCreate = false
    }
    
    private func editWork(_ work: Work) {
        workEditor.load(work: work)
        chatViewModel.loadFromWorkEditor()
        createSubTab = .chat
        showingCreate = true
    }
    
    private func loadUnreadCount() async {
        guard let userId = AuthService.shared.currentUser?.id else {
            unreadCount = 0
            return
        }
        
        do {
            unreadCount = try await ActivityService.shared.fetchUnreadCount(userId: userId)
        } catch {
            print("Failed to load unread count: \(error)")
        }
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
}
