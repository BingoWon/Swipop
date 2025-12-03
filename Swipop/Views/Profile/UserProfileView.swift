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
            let columnWidth = (geometry.size.width - 8) / 3
            
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderView(profile: viewModel.profile, isLoading: viewModel.isLoading)
                    ProfileStatsRow(
                        workCount: viewModel.workCount,
                        followerCount: viewModel.followerCount,
                        followingCount: viewModel.followingCount,
                        isLoading: viewModel.isLoading
                    )
                    actionButtons
                    workMasonryGrid(columnWidth: columnWidth)
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
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
                    .foregroundColor(viewModel.isFollowing ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(viewModel.isFollowing ? Color.white.opacity(0.15) : Color.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Work Masonry Grid
    
    private func workMasonryGrid(columnWidth: CGFloat) -> some View {
        MasonryGrid(works: viewModel.works, columnWidth: columnWidth, columns: 3, spacing: 2) { work in
            ProfileWorkCell(work: work, columnWidth: columnWidth)
        }
        .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID(), showLogin: .constant(false))
    }
    .preferredColorScheme(.dark)
}
