//
//  Work.swift
//  Swipop
//
//  Work model representing a frontend creation
//

import Foundation

struct Work: Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var title: String
    var description: String?
    var htmlContent: String?
    var cssContent: String?
    var jsContent: String?
    var thumbnailUrl: String?
    var tags: [String]?
    var chatMessages: [[String: Any]]?
    var isPublished: Bool
    var viewCount: Int
    var likeCount: Int
    var collectCount: Int
    var commentCount: Int
    var shareCount: Int
    let createdAt: Date
    var updatedAt: Date
    
    /// Associated creator profile (loaded via join)
    var creator: Profile?
    
    // MARK: - Equatable (exclude chatMessages which contains Any)
    
    static func == (lhs: Work, rhs: Work) -> Bool {
        lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.htmlContent == rhs.htmlContent &&
        lhs.cssContent == rhs.cssContent &&
        lhs.jsContent == rhs.jsContent &&
        lhs.isPublished == rhs.isPublished
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case htmlContent = "html_content"
        case cssContent = "css_content"
        case jsContent = "js_content"
        case thumbnailUrl = "thumbnail_url"
        case tags
        case chatMessages = "chat_messages"
        case isPublished = "is_published"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case collectCount = "collect_count"
        case commentCount = "comment_count"
        case shareCount = "share_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator = "users"
    }
}

// MARK: - Codable (custom for chatMessages)

extension Work: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        htmlContent = try container.decodeIfPresent(String.self, forKey: .htmlContent)
        cssContent = try container.decodeIfPresent(String.self, forKey: .cssContent)
        jsContent = try container.decodeIfPresent(String.self, forKey: .jsContent)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        isPublished = try container.decodeIfPresent(Bool.self, forKey: .isPublished) ?? false
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        collectCount = try container.decodeIfPresent(Int.self, forKey: .collectCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        shareCount = try container.decodeIfPresent(Int.self, forKey: .shareCount) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        creator = try container.decodeIfPresent(Profile.self, forKey: .creator)
        
        // Decode chatMessages from JSON data
        if let chatData = try container.decodeIfPresent(Data.self, forKey: .chatMessages),
           let messages = try? JSONSerialization.jsonObject(with: chatData) as? [[String: Any]] {
            chatMessages = messages
        } else if let messagesString = try? container.decode(String.self, forKey: .chatMessages),
                  let data = messagesString.data(using: .utf8),
                  let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            chatMessages = messages
        } else {
            chatMessages = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(htmlContent, forKey: .htmlContent)
        try container.encodeIfPresent(cssContent, forKey: .cssContent)
        try container.encodeIfPresent(jsContent, forKey: .jsContent)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(isPublished, forKey: .isPublished)
        try container.encode(viewCount, forKey: .viewCount)
        try container.encode(likeCount, forKey: .likeCount)
        try container.encode(collectCount, forKey: .collectCount)
        try container.encode(commentCount, forKey: .commentCount)
        try container.encode(shareCount, forKey: .shareCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(creator, forKey: .creator)
        
        // Encode chatMessages as JSON
        if let messages = chatMessages,
           let data = try? JSONSerialization.data(withJSONObject: messages) {
            try container.encode(data, forKey: .chatMessages)
        }
    }
}

// MARK: - Sample Data

extension Work {
    static let sample = Work(
        id: UUID(),
        userId: Profile.sample.id,
        title: "Neon Pulse",
        description: "A mesmerizing neon animation",
        htmlContent: """
            <div class="container">
                <div class="pulse"></div>
                <h1>Swipop</h1>
            </div>
        """,
        cssContent: """
            .container {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            }
            .pulse {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                background: linear-gradient(45deg, #a855f7, #6366f1);
                animation: pulse 2s ease-in-out infinite;
                box-shadow: 0 0 60px #a855f7;
            }
            @keyframes pulse {
                0%, 100% { transform: scale(1); opacity: 1; }
                50% { transform: scale(1.2); opacity: 0.8; }
            }
            h1 {
                margin-top: 40px;
                font-size: 32px;
                font-weight: 700;
                background: linear-gradient(90deg, #fff, #a855f7);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                letter-spacing: 4px;
            }
        """,
        jsContent: nil,
        thumbnailUrl: nil,
        tags: ["animation", "neon", "css"],
        chatMessages: nil,
        isPublished: true,
        viewCount: 1234,
        likeCount: 567,
        collectCount: 45,
        commentCount: 89,
        shareCount: 23,
        createdAt: Date(),
        updatedAt: Date(),
        creator: Profile.sample
    )
    
    static let samples: [Work] = [
        sample,
        Work(
            id: UUID(),
            userId: Profile.sample.id,
            title: "Particle Storm",
            description: "Interactive particle system",
            htmlContent: "<canvas id='canvas'></canvas>",
            cssContent: "canvas { width: 100%; height: 100%; }",
            jsContent: """
                const canvas = document.getElementById('canvas');
                const ctx = canvas.getContext('2d');
                canvas.width = window.innerWidth;
                canvas.height = window.innerHeight;
                
                const particles = [];
                for (let i = 0; i < 100; i++) {
                    particles.push({
                        x: Math.random() * canvas.width,
                        y: Math.random() * canvas.height,
                        vx: (Math.random() - 0.5) * 2,
                        vy: (Math.random() - 0.5) * 2,
                        size: Math.random() * 3 + 1
                    });
                }
                
                function animate() {
                    ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
                    ctx.fillRect(0, 0, canvas.width, canvas.height);
                    
                    particles.forEach(p => {
                        p.x += p.vx;
                        p.y += p.vy;
                        if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
                        if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
                        
                        ctx.beginPath();
                        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
                        ctx.fillStyle = '#a855f7';
                        ctx.fill();
                    });
                    
                    requestAnimationFrame(animate);
                }
                animate();
            """,
            thumbnailUrl: nil,
            tags: ["particle", "canvas", "javascript"],
            chatMessages: nil,
            isPublished: true,
            viewCount: 2345,
            likeCount: 890,
            collectCount: 78,
            commentCount: 123,
            shareCount: 45,
            createdAt: Date(),
            updatedAt: Date(),
            creator: Profile.sample
        ),
        Work(
            id: UUID(),
            userId: Profile.sample.id,
            title: "Gradient Wave",
            description: "Smooth gradient animation",
            htmlContent: "<div class='wave'></div>",
            cssContent: """
                .wave {
                    width: 100%;
                    height: 100%;
                    background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
                    background-size: 400% 400%;
                    animation: gradient 8s ease infinite;
                }
                @keyframes gradient {
                    0% { background-position: 0% 50%; }
                    50% { background-position: 100% 50%; }
                    100% { background-position: 0% 50%; }
                }
            """,
            jsContent: nil,
            thumbnailUrl: nil,
            tags: ["gradient", "animation", "css"],
            chatMessages: nil,
            isPublished: true,
            viewCount: 3456,
            likeCount: 1234,
            collectCount: 156,
            commentCount: 234,
            shareCount: 67,
            createdAt: Date(),
            updatedAt: Date(),
            creator: Profile.sample
        )
    ]
}

