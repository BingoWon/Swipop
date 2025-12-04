//
//  MainTabView.swift
//  Swipop
//
//  Main tab navigation with iOS 26 and iOS 18 variants
//

import SwiftUI

struct MainTabView: View {
    @Binding var showLogin: Bool
    @State private var selectedTab = 0
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
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
                iOS26Content
            } else {
                iOS18Content
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
    
    // MARK: - iOS 26
    
    @available(iOS 26.0, *)
    private var iOS26Content: some View {
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
    }
    
    // MARK: - iOS 18
    
    private var iOS18Content: some View {
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

#Preview {
    MainTabView(showLogin: .constant(false))
}
