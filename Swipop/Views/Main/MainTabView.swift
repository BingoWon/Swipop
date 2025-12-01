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
            
            Tab("Create", systemImage: "plus.square.fill", value: 1) {
                CreateView(showLogin: $showLogin)
            }
            
            Tab("Profile", systemImage: "person.fill", value: 2) {
                ProfileView(showLogin: $showLogin)
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 3, role: .search) {
                SearchView(searchText: $searchText)
            }
        }
        .modifier(FeedBottomAccessory(
            isVisible: selectedTab == 0,
            showDetail: $showWorkDetail
        ))
        .tint(.white)
        .sheet(isPresented: $showWorkDetail) {
            if let work = feed.currentWork {
                WorkDetailSheet(work: work, showLogin: $showLogin)
            }
        }
    }
}

// MARK: - Feed Bottom Accessory

private struct FeedBottomAccessory: ViewModifier {
    
    let isVisible: Bool
    @Binding var showDetail: Bool
    let feed = FeedViewModel.shared
    
    func body(content: Content) -> some View {
        if isVisible {
            content.tabViewBottomAccessory {
                HStack(spacing: 0) {
                    // Work info - tap for detail
                    Button { showDetail = true } label: {
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
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
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
        } else {
            content
        }
    }
}

#Preview {
    MainTabView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
