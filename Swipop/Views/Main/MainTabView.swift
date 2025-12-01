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
    @State private var searchText = ""
    @State private var showWorkDetail = false
    
    private let feed = FeedViewModel.shared
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                FeedView(showLogin: $showLogin)
            }
            
            Tab("Inbox", systemImage: "bell.fill", value: 1) {
                InboxView()
            }
            
            Tab("Create", systemImage: "plus.square.fill", value: 2) {
                CreateView(showLogin: $showLogin)
            }
            
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(showLogin: $showLogin)
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 4, role: .search) {
                SearchView(searchText: $searchText)
            }
        }
        .tabViewBottomAccessory {
            BottomAccessory(
                isOnFeed: selectedTab == 0,
                showDetail: $showWorkDetail,
                goToFeed: { selectedTab = 0 }
            )
        }
        .tint(.white)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
    }
}

// MARK: - Bottom Accessory

private struct BottomAccessory: View {
    
    let isOnFeed: Bool
    @Binding var showDetail: Bool
    let goToFeed: () -> Void
    
    let feed = FeedViewModel.shared
    
    var body: some View {
        if isOnFeed {
            feedModeContent
        } else {
            returnModeContent
        }
    }
    
    // MARK: - Feed Mode (上下切换作品)
    
    private var feedModeContent: some View {
        HStack(spacing: 0) {
            // Work info - tap for detail
            Button { showDetail = true } label: {
                workInfoLabel
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 28)
            
            // Navigation
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
                
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 18)
                
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
        .foregroundStyle(.white)
    }
    
    // MARK: - Return Mode (点击返回 Feed)
    
    private var returnModeContent: some View {
        Button(action: goToFeed) {
            HStack(spacing: 0) {
                workInfoLabel
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 28)
                
                // Continue watching
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
    
    // MARK: - Shared Work Info
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 28, height: 28)
                .overlay(
                    Text("C")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feed.currentWork?.title ?? "Swipop")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("@creator")
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
}

#Preview {
    MainTabView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
