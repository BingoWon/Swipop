//
//  Work.swift
//  Swipop
//
//  Work model representing a frontend creation
//

import Foundation

struct Work: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var title: String
    var description: String?
    var htmlContent: String?
    var cssContent: String?
    var jsContent: String?
    var thumbnailUrl: String?
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
        case isPublished = "is_published"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case collectCount = "collect_count"
        case commentCount = "comment_count"
        case shareCount = "share_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator = "profiles"
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

