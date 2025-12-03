//
//  ProfileComponents.swift
//  Swipop
//
//  Shared UI components for profile views
//

import SwiftUI

// MARK: - Compact Profile Header (Modern Design)

struct ProfileHeaderView: View {
    let profile: Profile?
    var isLoading = false
    var showEditButton = false
    var onEditTapped: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar + Name + Handle row
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.brand)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(profile?.initial ?? "U")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .redacted(reason: isLoading ? .placeholder : [])
                
                // Name + Handle
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.name ?? "User")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("@\(profile?.handle ?? "user")")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .redacted(reason: isLoading ? .placeholder : [])
                
                Spacer()
                
                // Edit button (optional)
                if showEditButton {
                    Button {
                        onEditTapped?()
                    } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondaryBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Bio
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }
            
            // Links
            if let links = profile?.links, !links.isEmpty {
                linksView(links)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func linksView(_ links: [ProfileLink]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(links) { link in
                    LinkChip(link: link)
                }
            }
        }
    }
}

// MARK: - Link Chip

private struct LinkChip: View {
    let link: ProfileLink
    
    var body: some View {
        Link(destination: URL(string: link.url) ?? URL(string: "https://swipop.app")!) {
            HStack(spacing: 6) {
                Image(systemName: iconForLink(link))
                    .font(.system(size: 12))
                Text(link.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Color.brand)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.brand.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private func iconForLink(_ link: ProfileLink) -> String {
        let lowercased = link.url.lowercased()
        if lowercased.contains("github") { return "link" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "link" }
        if lowercased.contains("instagram") { return "link" }
        if lowercased.contains("youtube") { return "link" }
        if lowercased.contains("linkedin") { return "link" }
        return "link"
    }
}

// MARK: - Compact Stats Row

struct ProfileStatsRow: View {
    let workCount: Int
    let likeCount: Int
    let followerCount: Int
    let followingCount: Int
    var isLoading = false
    
    var body: some View {
        HStack(spacing: 0) {
            statItem(value: workCount, label: "Works")
            
            Divider()
                .frame(height: 24)
                .overlay(Color.border)
            
            statItem(value: followerCount, label: "Followers")
            
            Divider()
                .frame(height: 24)
                .overlay(Color.border)
            
            statItem(value: followingCount, label: "Following")
            
            Divider()
                .frame(height: 24)
                .overlay(Color.border)
            
            statItem(value: likeCount, label: "Likes")
        }
        .padding(.vertical, 12)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .redacted(reason: isLoading ? .placeholder : [])
    }
    
    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value.formatted)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .primary : .tertiary)
                
                Rectangle()
                    .fill(isSelected ? Color.primary : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

