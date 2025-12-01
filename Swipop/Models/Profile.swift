//
//  Profile.swift
//  Swipop
//
//  User profile model
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
        createdAt: Date(),
        updatedAt: Date()
    )
}

