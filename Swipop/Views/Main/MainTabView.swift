//
//  MainTabView.swift
//  Swipop
//
//  Main tab navigation with floating accessory
//

import SwiftUI

struct MainTabView: View {
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
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
            
            // Floating Create accessory
            if selectedTab == 1 {
                FloatingCreateAccessory(createSubTab: $createSubTab)
            }
        }
        .tint(selectedTab == 1 ? .brand : .primary)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
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

// MARK: - Floating Create Accessory

private struct FloatingCreateAccessory: View {
    @Binding var createSubTab: CreateSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                TabButton(tab: tab, isSelected: createSubTab == tab) {
                    createSubTab = tab
                }
                
                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 20)
                        .overlay(Color.white.opacity(0.15))
                }
            }
        }
        .frame(height: 52)
        .background { glassBackground }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}

private struct TabButton: View {
    let tab: CreateSubTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? tab.color : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
}
