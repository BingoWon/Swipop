//
//  ProfileComponents.swift
//  Swipop
//
//  Shared UI components for profile views
//

import SwiftUI

// MARK: - Stat Column

struct ProfileStatColumn: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value.formatted)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Work Thumbnail

struct WorkThumbnail: View {
    let work: Work
    var showDraftBadge = false
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: "1a1a2e"))
            .aspectRatio(1, contentMode: .fill)
            .overlay { thumbnailContent }
            .overlay(alignment: .topTrailing) { draftBadge }
            .clipped()
    }
    
    @ViewBuilder
    private var thumbnailContent: some View {
        if let urlString = work.thumbnailUrl, let url = URL(string: urlString) {
            // Cover image
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    placeholderContent
                @unknown default:
                    placeholderContent
                }
            }
        } else {
            placeholderContent
        }
    }
    
    private var placeholderContent: some View {
        VStack(spacing: 4) {
            Text(displayText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
            
            if !work.title.isEmpty {
                Text(work.title)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private var draftBadge: some View {
        if showDraftBadge {
            Text("Draft")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(4)
                .padding(4)
        }
    }
    
    private var displayText: String {
        if !work.title.isEmpty {
            return String(work.title.prefix(2)).uppercased()
        }
        if work.htmlContent?.isEmpty == false { return "H" }
        if work.cssContent?.isEmpty == false { return "C" }
        if work.jsContent?.isEmpty == false { return "J" }
        return "?"
    }
}

// MARK: - Profile Tab Button

struct ProfileTabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let profile: Profile?
    var isLoading = false
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.brand)
                .frame(width: 88, height: 88)
                .overlay(
                    Text(profile?.username?.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )
                .redacted(reason: isLoading ? .placeholder : [])
            
            Text(profile?.displayName ?? profile?.username ?? "User")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .redacted(reason: isLoading ? .placeholder : [])
            
            if let username = profile?.username {
                Text("@\(username)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Stats Row

struct ProfileStatsRow: View {
    let workCount: Int
    let followerCount: Int
    let followingCount: Int
    var isLoading = false
    
    var body: some View {
        HStack(spacing: 40) {
            ProfileStatColumn(value: workCount, label: "Works")
            ProfileStatColumn(value: followerCount, label: "Followers")
            ProfileStatColumn(value: followingCount, label: "Following")
        }
        .padding(.vertical, 16)
        .redacted(reason: isLoading ? .placeholder : [])
    }
}
