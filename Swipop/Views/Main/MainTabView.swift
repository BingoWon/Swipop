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
    @State private var previousTab = 0
    @State private var showWorkDetail = false
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
    private let feed = FeedViewModel.shared
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
        let editor = WorkEditorViewModel()
        self._workEditor = State(initialValue: editor)
        self._chatViewModel = State(initialValue: ChatViewModel(workEditor: editor))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin)
            }
            
            Tab("Inbox", systemImage: "bell.fill", value: 1) {
                InboxView()
            }
            
            Tab("Profile", systemImage: "person.fill", value: 2) {
                ProfileView(showLogin: $showLogin)
            }
            
            Tab("Create", systemImage: "plus", value: 3, role: .search) {
                CreateView(showLogin: $showLogin, workEditor: workEditor, chatViewModel: chatViewModel, selectedSubTab: $createSubTab)
            }
        }
        .tabViewBottomAccessory {
            BottomAccessoryContent(
                selectedTab: selectedTab,
                createSubTab: $createSubTab,
                showWorkDetail: $showWorkDetail,
                goToFeed: { selectedTab = 0 }
            )
        }
        .tint(.white)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // When LEAVING Create tab, save and reset for next visit
            if oldValue == 3 && newValue != 3 {
                Task {
                    await workEditor.saveAndReset()
                    chatViewModel.clear()
                    createSubTab = .chat
                }
            }
            previousTab = oldValue
        }
    }
}

// MARK: - Bottom Accessory Content (extracted to prevent unnecessary redraws)

private struct BottomAccessoryContent: View {
    let selectedTab: Int
    @Binding var createSubTab: CreateSubTab
    @Binding var showWorkDetail: Bool
    let goToFeed: () -> Void
    
    var body: some View {
        if selectedTab == 3 {
            CreateSubTabBar(selectedTab: $createSubTab)
        } else {
            BottomAccessory(
                isOnFeed: selectedTab == 0,
                showDetail: $showWorkDetail,
                goToFeed: goToFeed
            )
        }
    }
}

// MARK: - Bottom Accessory

private struct BottomAccessory: View {
    let isOnFeed: Bool
    @Binding var showDetail: Bool
    let goToFeed: () -> Void
    
    private let feed = FeedViewModel.shared
    
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        if isOnFeed {
            feedModeContent
        } else {
            returnModeContent
        }
    }
    
    private var feedModeContent: some View {
        HStack(spacing: 0) {
            Button { showDetail = true } label: {
                workInfoLabel
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 28).overlay(Color.white.opacity(0.2))
            navigationButtons
        }
        .foregroundStyle(.white)
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
            
            Divider().frame(height: 18).overlay(Color.white.opacity(0.15))
            
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
    
    private var returnModeContent: some View {
        Button(action: goToFeed) {
            HStack(spacing: 0) {
                workInfoLabel.frame(maxWidth: .infinity)
                
                Divider().frame(height: 28).overlay(Color.white.opacity(0.2))
                
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 12))
                    Text("Continue").font(.system(size: 13, weight: .medium))
                }
                .frame(width: 100)
            }
            .foregroundStyle(.white)
        }
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
            
            if isOnFeed {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
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
