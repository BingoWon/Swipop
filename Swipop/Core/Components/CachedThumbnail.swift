//
//  CachedThumbnail.swift
//  Swipop
//
//  Cached thumbnail image using Kingfisher
//

import SwiftUI
import Kingfisher

/// Cached thumbnail with Kingfisher (memory + disk cache)
struct CachedThumbnail: View {
    let url: URL?
    let size: CGSize?
    let placeholder: AnyView
    
    /// Initialize with explicit size (recommended for grid cells)
    init(url: URL?, size: CGSize, @ViewBuilder placeholder: () -> some View) {
        self.url = url
        self.size = size
        self.placeholder = AnyView(placeholder())
    }
    
    /// Initialize without size (for flexible layouts like settings preview)
    init(url: URL?, @ViewBuilder placeholder: () -> some View) {
        self.url = url
        self.size = nil
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        if let url {
            if let size {
                // Fixed size mode: fill and clip
                KFImage(url)
                    .placeholder { placeholder.frame(width: size.width, height: size.height) }
                    .fade(duration: 0.2)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                // Flexible mode: just resizable, let parent control size
                KFImage(url)
                    .placeholder { placeholder }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFill()
            }
        } else {
            if let size {
                placeholder.frame(width: size.width, height: size.height)
            } else {
                placeholder
            }
        }
    }
}

// MARK: - Convenience initializers

extension CachedThumbnail {
    /// Work thumbnail with gradient placeholder
    init(work: Work, transform: ThumbnailTransform, size: CGSize) {
        let url: URL? = switch transform {
        case .small: work.smallThumbnailURL
        case .medium: work.mediumThumbnailURL
        }
        
        self.init(url: url, size: size) {
            WorkThumbnailPlaceholder(title: work.title)
        }
    }
}

// MARK: - Placeholder

struct WorkThumbnailPlaceholder: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white.opacity(0.6) : .primary.opacity(0.5)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brand.opacity(0.3), Color.brand.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Text(displayTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(8)
        }
    }
}

// MARK: - Cache Configuration

enum ThumbnailCache {
    /// Configure Kingfisher cache on app launch
    static func configure() {
        let cache = ImageCache.default
        
        // Memory: 100 MB
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        
        // Disk: 500 MB, 7 days expiration
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
    }
    
    /// Clear all cache
    static func clearAll() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
    
    /// Get cache size
    static func diskCacheSize() async -> UInt {
        await withCheckedContinuation { continuation in
            ImageCache.default.calculateDiskStorageSize { result in
                switch result {
                case .success(let size): continuation.resume(returning: size)
                case .failure: continuation.resume(returning: 0)
                }
            }
        }
    }
}
