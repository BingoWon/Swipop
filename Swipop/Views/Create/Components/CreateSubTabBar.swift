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
                TabButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
                
                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 20)
                        .overlay(Color.white.opacity(0.1))
                }
            }
        }
    }
}

// MARK: - Tab Button (extracted for performance)

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
            .foregroundStyle(isSelected ? tab.color : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tab.color.opacity(0.15))
                        .padding(.horizontal, 8)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
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

