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
    @State private var isViewingWork = false
    @State private var showWorkDetail = false
    @State private var workEditor: WorkEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    
    private let feed = FeedViewModel.shared
    
    /// Custom binding to detect re-selection of Create tab
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
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
            BottomAccessoryContent(
                selectedTab: selectedTab,
                isViewingWork: isViewingWork,
                createSubTab: $createSubTab,
                showWorkDetail: $showWorkDetail,
                continueToWork: continueToWork
            )
        }
        .tint(selectedTab == 3 ? .brand : .white)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == 3 && newValue != 3 {
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
        selectedTab = 3
    }
    
    @MainActor
    private func createNewWork() async {
        await workEditor.saveAndReset()
        chatViewModel.clear()
        createSubTab = .chat
    }
    
    /// Continue to last viewed work
    private func continueToWork() {
        selectedTab = 0
        isViewingWork = true
    }
}

// MARK: - Bottom Accessory Content

private struct BottomAccessoryContent: View {
    let selectedTab: Int
    let isViewingWork: Bool
    @Binding var createSubTab: CreateSubTab
    @Binding var showWorkDetail: Bool
    let continueToWork: () -> Void
    
    var body: some View {
        if selectedTab == 3 {
            // Create tab: independent sub-tab bar
            CreateSubTabBar(selectedTab: $createSubTab)
        } else if selectedTab == 0 && isViewingWork {
            // Home tab viewing work: work info + navigation
            WorkModeAccessory(showDetail: $showWorkDetail)
        } else {
            // All other cases: Continue to last work
            ContinueAccessory(onContinue: continueToWork)
        }
    }
}

// MARK: - Work Mode Accessory (viewing work in Home)

private struct WorkModeAccessory: View {
    @Binding var showDetail: Bool
    
    private let feed = FeedViewModel.shared
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
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
            
            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
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
    
    private var creatorInitial: String {
        String((creator?.displayName ?? creator?.username ?? "S").prefix(1)).uppercased()
    }
}

// MARK: - Continue Accessory (return to last work)

private struct ContinueAccessory: View {
    let onContinue: () -> Void
    
    private let feed = FeedViewModel.shared
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        Button(action: onContinue) {
            HStack(spacing: 0) {
                workInfoLabel
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 28)
                    .overlay(Color.white.opacity(0.2))
                
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Continue")
                        .font(.system(size: 13, weight: .medium))
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
