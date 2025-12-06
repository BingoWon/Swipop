//
//  Profile.swift
//  Swipop
//
//  User profile model
//

import Foundation

// MARK: - Profile Link

struct ProfileLink: Codable, Equatable, Identifiable {
    var id: UUID = .init()
    var title: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case title, url
    }

    init(title: String = "", url: String = "") {
        self.title = title
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)
    }
}

// MARK: - Profile

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var links: [ProfileLink]
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Best available display name (displayName > username > "User")
    var name: String {
        displayName ?? username ?? "User"
    }

    /// Username for @ mention (username > displayName sanitized > "user")
    var handle: String {
        username ?? displayName?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "user"
    }

    /// First character for avatar placeholder
    var initial: String {
        String((displayName ?? username ?? "U").prefix(1)).uppercased()
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case links
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        links = try container.decodeIfPresent([ProfileLink].self, forKey: .links) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    init(id: UUID, username: String?, displayName: String?, avatarUrl: String?, bio: String?, links: [ProfileLink] = [], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.links = links
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sample Data

extension Profile {
    static let sample = Profile(
        id: UUID(),
        username: "creator",
        displayName: "Creative Dev",
        avatarUrl: nil,
        bio: "Building cool stuff with code ✨",
        links: [
            ProfileLink(title: "GitHub", url: "https://github.com/creator"),
            ProfileLink(title: "Twitter", url: "https://twitter.com/creator"),
        ],
        createdAt: Date(),
        updatedAt: Date()
    )
}
