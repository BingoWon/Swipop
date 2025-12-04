//
//  MainTabView.swift
//  Swipop
//
//  iOS 26 liquid glass tab bar with iOS 18 fallback
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
                // Re-selecting Home tab: return to Discover grid
                if newValue == 0 && selectedTab == 0 && isViewingWork {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isViewingWork = false
                    }
                }
                // Re-selecting Create tab: create new work
                else if newValue == 1 && selectedTab == 1 {
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
    
    // MARK: - iOS 26 Tab View
    
    @available(iOS 26.0, *)
    private var iOS26TabView: some View {
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
        .tabViewBottomAccessory {
            iOS26BottomAccessory(
                selectedTab: selectedTab,
                isViewingWork: isViewingWork,
                createSubTab: $createSubTab,
                showWorkDetail: $showWorkDetail
            )
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
    
    // MARK: - iOS 18 Tab View (Fallback)
    
    private var iOS18TabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: tabSelection) {
                FeedView(showLogin: $showLogin, isViewingWork: $isViewingWork)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                    .toolbar(isViewingWork ? .hidden : .visible, for: .tabBar)
                
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
            
            // Floating accessory for iOS 18
            if selectedTab == 1 {
                iOS18CreateAccessory(createSubTab: $createSubTab)
            } else if selectedTab == 0 && isViewingWork {
                iOS18WorkAccessory(showDetail: $showWorkDetail)
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
    let isViewingWork: Bool
    @Binding var createSubTab: CreateSubTab
    @Binding var showWorkDetail: Bool
    
    var body: some View {
        if selectedTab == 1 {
            CreateSubTabBar(selectedTab: $createSubTab)
        } else if selectedTab == 0 && isViewingWork {
            iOS26WorkAccessory(showDetail: $showWorkDetail)
        }
    }
}

// MARK: - iOS 26 Work Accessory

@available(iOS 26.0, *)
private struct iOS26WorkAccessory: View {
    @Binding var showDetail: Bool
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    private let feed = FeedViewModel.shared
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        switch placement {
        case .inline:
            workInfoLabel
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
        case .expanded:
            HStack(spacing: 0) {
                Button { showDetail = true } label: {
                    workInfoLabel
                }
                Spacer(minLength: 0)
                Divider().frame(height: 28).overlay(Color.border)
                navigationButtons
            }
            .foregroundStyle(.primary)
        case .none:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            creatorAvatar
            workTitleAndHandle
        }
        .padding(.leading, 12)
    }
    
    private var creatorAvatar: some View {
        Circle()
            .fill(Color.brand)
            .frame(width: 28, height: 28)
            .overlay {
                Text(creator?.initial ?? "?")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
    
    private var workTitleAndHandle: some View {
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

// MARK: - iOS 18 Floating Accessory (Liquid Glass Style)

private struct iOS18WorkAccessory: View {
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
            
            navigationButtons
        }
        .foregroundStyle(.primary)
        .frame(height: 52)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(creator?.initial ?? "?")
                        .font(.system(size: 13, weight: .bold))
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
        .padding(.leading, 14)
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
                    .frame(width: 44, height: 44)
            }
            .opacity(feed.currentIndex == 0 ? 0.3 : 1)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.trailing, 4)
    }
}

// MARK: - iOS 18 Create Accessory (Floating Style)

private struct iOS18CreateAccessory: View {
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
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
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
