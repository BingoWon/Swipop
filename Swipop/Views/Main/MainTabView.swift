//
//  MainTabView.swift
//  Swipop
//
//  Main tab navigation with platform-specific bottom accessory
//

import SwiftUI

struct MainTabView: View {
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    @State private var showWorkDetail = false
    
    private let feed = FeedViewModel.shared
    
    /// Custom binding to detect re-selection of tabs
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // Re-selecting Create tab: create new work
                if newValue == 1 && selectedTab == 1 {
                    Task { await createNewWork() }
                }
                selectedTab = newValue
            }
        )
    }
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
        let editor = WorkEditorViewModel()
        self._workEditor = State(initialValue: editor)
        self._chatViewModel = State(initialValue: ChatViewModel(workEditor: editor))
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                iOS26TabView
            } else {
                iOS18TabView
            }
        }
        .tint(selectedTab == 1 ? .brand : .primary)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == 1 && newValue != 1 {
                Task {
                    await workEditor.saveAndReset()
                    chatViewModel.clear()
                    createSubTab = .chat
                }
            }
        }
    }
    
    // MARK: - iOS 26 Tab View (Native tabViewBottomAccessory)
    
    @available(iOS 26.0, *)
    private var iOS26TabView: some View {
        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin)
            }
            
            Tab("Create", systemImage: "wand.and.stars", value: 1) {
                CreateView(showLogin: $showLogin, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: $createSubTab)
            }
            
            Tab("Inbox", systemImage: "bell.fill", value: 2) {
                InboxView()
            }
            
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(showLogin: $showLogin, editWork: editWork)
            }
        }
        .tabViewBottomAccessory {
            iOS26BottomAccessory(
                selectedTab: selectedTab,
                createSubTab: $createSubTab,
                showWorkDetail: $showWorkDetail
            )
        }
    }
    
    // MARK: - iOS 18 Tab View (Manual floating accessory)
    
    private var iOS18TabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: tabSelection) {
                FeedView(showLogin: $showLogin)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                
                CreateView(showLogin: $showLogin, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: $createSubTab)
                    .tabItem { Label("Create", systemImage: "wand.and.stars") }
                    .tag(1)
                
                InboxView()
                    .tabItem { Label("Inbox", systemImage: "bell.fill") }
                    .tag(2)
                
                ProfileView(showLogin: $showLogin, editWork: editWork)
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(3)
            }
            
            // Floating Create accessory (iOS 18 only)
            if selectedTab == 1 {
                FloatingCreateAccessory(createSubTab: $createSubTab)
            }
        }
    }
    
    // MARK: - Actions
    
    private func editWork(_ work: Work) {
        workEditor.load(work: work)
        chatViewModel.loadFromWorkEditor()
        createSubTab = .chat
        selectedTab = 1
    }
    
    @MainActor
    private func createNewWork() async {
        await workEditor.saveAndReset()
        chatViewModel.clear()
        createSubTab = .chat
    }
}

// MARK: - iOS 26 Bottom Accessory

@available(iOS 26.0, *)
private struct iOS26BottomAccessory: View {
    let selectedTab: Int
    @Binding var createSubTab: CreateSubTab
    @Binding var showWorkDetail: Bool
    
    var body: some View {
        if selectedTab == 1 {
            CreateSubTabContent(selectedTab: $createSubTab)
        }
    }
}

@available(iOS 26.0, *)
private struct CreateSubTabContent: View {
    @Binding var selectedTab: CreateSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? tab.color : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 20)
                        .overlay(Color.border)
                }
            }
        }
    }
}

// MARK: - iOS 18 Floating Create Accessory

private struct FloatingCreateAccessory: View {
    @Binding var createSubTab: CreateSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                Button {
                    createSubTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(createSubTab == tab ? tab.color : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 20)
                        .overlay(Color.white.opacity(0.15))
                }
            }
        }
        .frame(height: 52)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
}
