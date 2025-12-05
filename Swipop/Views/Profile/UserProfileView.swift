//
//  UserProfileView.swift
//  Swipop
//
//  View other user's profile
//

import SwiftUI

struct UserProfileView: View {
    
    let userId: UUID
    @Binding var showLogin: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OtherUserProfileViewModel
    
    init(userId: UUID, showLogin: Binding<Bool>) {
        self.userId = userId
        self._showLogin = showLogin
        self._viewModel = State(initialValue: OtherUserProfileViewModel(userId: userId))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 8) / 3, 1)
            
            ScrollView {
                VStack(spacing: 8) {
                    ProfileHeaderView(profile: viewModel.profile, isLoading: viewModel.isLoading)
                    
                    ProfileStatsRow(
                        workCount: viewModel.workCount,
                        likeCount: viewModel.likeCount,
                        followerCount: viewModel.followerCount,
                        followingCount: viewModel.followingCount,
                        isLoading: viewModel.isLoading
                    )
                    
                    actionButtons
                    
                    workMasonryGrid(columnWidth: columnWidth)
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.toggleFollow() }
            } label: {
                Text(viewModel.isFollowing ? "Following" : "Follow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(viewModel.isFollowing ? .primary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(viewModel.isFollowing ? Color.secondaryBackground : Color.brand)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Work Masonry Grid
    
    private func workMasonryGrid(columnWidth: CGFloat) -> some View {
        Group {
            if viewModel.works.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No works yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                MasonryGrid(works: viewModel.works, columnWidth: columnWidth, columns: 3, spacing: 2) { work in
                    ProfileWorkCell(work: work, columnWidth: columnWidth)
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID(), showLogin: .constant(false))
    }
}
