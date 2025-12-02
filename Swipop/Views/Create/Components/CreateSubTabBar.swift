//
//  CreateSubTabBar.swift
//  Swipop
//
//  Sub-tab selector for Create page (shown in tabViewBottomAccessory)
//

import SwiftUI

struct CreateSubTabBar: View {
    @Binding var selectedTab: CreateSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                tabButton(tab)
                
                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 20)
                        .overlay(Color.white.opacity(0.1))
                }
            }
        }
    }
    
    private func tabButton(_ tab: CreateSubTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? tab.color : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tab.color.opacity(0.15))
                        .padding(.horizontal, 8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            CreateSubTabBar(selectedTab: .constant(.chat))
                .padding()
                .background(.ultraThinMaterial)
        }
    }
}

