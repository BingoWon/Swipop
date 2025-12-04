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
    @State private var isViewingWork = false
    @State private var showWorkDetail = false
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
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
        Group {
            if selectedTab == 0 && isViewingWork {
                iOS26TabViewWithAccessory
            } else {
                iOS26TabViewBase
            }
        }
    }
    
    @available(iOS 26.0, *)
    private var iOS26TabViewBase: some View {
        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin, isViewingWork: $isViewingWork)
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
    
    @available(iOS 26.0, *)
    private var iOS26TabViewWithAccessory: some View {
        iOS26TabViewBase
            .tabViewBottomAccessory {
                WorkAccessoryContent(showDetail: $showWorkDetail)
            }
    }
    
    // MARK: - iOS 18 Tab View
    
    private var iOS18TabView: some View {
        TabView(selection: tabSelection) {
            FeedView(showLogin: $showLogin, isViewingWork: $isViewingWork)
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

// MARK: - iOS 26 Work Accessory Content

@available(iOS 26.0, *)
private struct WorkAccessoryContent: View {
    @Binding var showDetail: Bool
    
    private let feed = FeedViewModel.shared
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        HStack(spacing: 0) {
            Button { showDetail = true } label: {
                workInfoLabel
            }
            
            Spacer(minLength: 0)
            
            Divider().frame(height: 28).overlay(Color.border)
            
            navigationButtons
        }
        .foregroundStyle(.primary)
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 28, height: 28)
                .overlay {
                    Text(creator?.initial ?? "?")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentWork?.title.isEmpty == false ? currentWork!.title : "Untitled")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("@\(creator?.handle ?? "unknown")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 12)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToPrevious()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 36)
            }
            .opacity(feed.currentIndex == 0 ? 0.3 : 1)
            
            Divider().frame(height: 18).overlay(Color.border)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 36)
            }
        }
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
}
