//
//  ProjectAccessory.swift
//  Swipop
//
//  Floating project accessory with Liquid Glass (iOS 26) / Material (iOS 18)
//

import SwiftUI

// MARK: - Project Accessory Content (Shared)

struct ProjectAccessoryContent: View {
    @Binding var showDetail: Bool

    private let feed = FeedViewModel.shared
    private var currentProject: Project? { feed.currentProject }
    private var creator: Profile? { currentProject?.creator }

    var body: some View {
        HStack(spacing: 0) {
            Button { showDetail = true } label: {
                projectInfoLabel
            }

            Spacer(minLength: 0)

            Divider().frame(height: 18).overlay(Color.border)

            navigationButtons

            Spacer().frame(width: 4)
        }
        .foregroundStyle(.primary)
    }

    private var projectInfoLabel: some View {
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
                Text(currentProject?.displayTitle ?? "Untitled")
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
                    .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 36)
            }
        }
    }
}

// MARK: - Floating Project Accessory

struct FloatingProjectAccessory: View {
    @Binding var showDetail: Bool

    var body: some View {
        ProjectAccessoryContent(showDetail: $showDetail)
            .frame(height: 48)
            .glassBackground()
            .padding(.horizontal, 20)
    }
}

// MARK: - Floating Create Accessory

struct FloatingCreateAccessory: View {
    @Binding var selectedSubTab: CreateSubTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                tabButton(for: tab)

                if tab != CreateSubTab.allCases.last {
                    Divider()
                        .frame(height: 18)
                        .overlay(Color.border)
                }
            }
        }
        .frame(height: 48)
        .glassBackground()
        .padding(.horizontal, 20)
    }

    private func tabButton(for tab: CreateSubTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedSubTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(selectedSubTab == tab ? tab.color : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
    }
}

#Preview("Project Accessory") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingProjectAccessory(showDetail: .constant(false))
        }
    }
}

#Preview("Create Accessory") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingCreateAccessory(selectedSubTab: .constant(.chat))
        }
    }
}
