//
//  MainTabView.swift
//  Swipop
//
//  iOS 26 liquid glass tab bar
//

import SwiftUI

struct MainTabView: View {
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var isViewingWork = false  // Track if viewing fullscreen work
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
    /// Custom binding to detect re-selection of Create tab
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // If Create tab is re-selected while already on it, create new work
                if newValue == 3 && selectedTab == 3 {
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
        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin, isViewingWork: $isViewingWork)
            }
            
            Tab("Inbox", systemImage: "bell.fill", value: 1) {
                InboxView()
            }
            
            Tab("Profile", systemImage: "person.fill", value: 2) {
                ProfileView(showLogin: $showLogin, editWork: editWork)
            }
            
            Tab("Create", systemImage: "wand.and.stars", value: 3, role: .search) {
                CreateView(showLogin: $showLogin, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: $createSubTab)
            }
        }
        .tabViewBottomAccessory {
            // Only show accessory when NOT on home grid OR on Create tab
            if shouldShowAccessory {
                BottomAccessoryContent(
                    selectedTab: selectedTab,
                    createSubTab: $createSubTab
                )
            }
        }
        .tint(selectedTab == 3 ? .brand : .white)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .onChange(of: selectedTab) { oldValue, newValue in
            // When LEAVING Create tab, save and reset for next visit
            if oldValue == 3 && newValue != 3 {
                Task {
                    await workEditor.saveAndReset()
                    chatViewModel.clear()
                    createSubTab = .chat
                }
            }
        }
    }
    
    /// Determine if bottom accessory should be shown
    private var shouldShowAccessory: Bool {
        // Hide on Home grid view (show only when viewing work fullscreen)
        if selectedTab == 0 {
            return false  // Always hide on Home (grid view)
        }
        // Show on Create tab
        if selectedTab == 3 {
            return true
        }
        // Show on other tabs
        return true
    }
    
    // MARK: - Actions
    
    /// Navigate to Create tab with a work loaded for editing
    private func editWork(_ work: Work) {
        workEditor.load(work: work)
        chatViewModel.loadFromWorkEditor()
        createSubTab = .chat
        selectedTab = 3
    }
    
    /// Save current work and reset to create a new one
    @MainActor
    private func createNewWork() async {
        await workEditor.saveAndReset()
        chatViewModel.clear()
        createSubTab = .chat
    }
}

// MARK: - Bottom Accessory Content

private struct BottomAccessoryContent: View {
    let selectedTab: Int
    @Binding var createSubTab: CreateSubTab
    
    var body: some View {
        if selectedTab == 3 {
            CreateSubTabBar(selectedTab: $createSubTab)
        } else {
            // Non-home tabs: show current work info with return button
            ReturnToHomeAccessory()
        }
    }
}

// MARK: - Return to Home Accessory

private struct ReturnToHomeAccessory: View {
    private let feed = FeedViewModel.shared
    
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        HStack(spacing: 0) {
            workInfoLabel
                .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 28)
                .overlay(Color.white.opacity(0.2))
            
            HStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                Text("Home")
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(width: 80)
        }
        .foregroundStyle(.white)
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 28, height: 28)
                .overlay {
                    Text(creatorInitial)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentWork?.title ?? "Swipop")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("@\(creator?.username ?? "swipop")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
    }
    
    private var creatorInitial: String {
        String((creator?.displayName ?? creator?.username ?? "S").prefix(1)).uppercased()
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
