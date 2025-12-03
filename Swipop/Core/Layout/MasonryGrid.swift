//
//  MasonryGrid.swift
//  Swipop
//
//  Waterfall/Masonry grid layout (Xiaohongshu style)
//

import SwiftUI

struct MasonryGrid<Item: Identifiable, Content: View>: View {
    
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    let heightProvider: (Item) -> CGFloat
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 4,
        @ViewBuilder content: @escaping (Item) -> Content,
        heightProvider: @escaping (Item) -> CGFloat
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
        self.heightProvider = heightProvider
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex)) { item in
                        content(item)
                    }
                }
            }
        }
        .padding(.horizontal, spacing)
    }
    
    /// Distribute items to columns based on cumulative height (greedy algorithm)
    private func itemsForColumn(_ column: Int) -> [Item] {
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)
        var columnItems: [[Item]] = Array(repeating: [], count: columns)
        
        for item in items {
            // Find the shortest column
            let shortestColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            
            // Add item to shortest column
            columnItems[shortestColumn].append(item)
            columnHeights[shortestColumn] += heightProvider(item) + spacing
        }
        
        return columnItems[column]
    }
}

// MARK: - Work-specific extension

extension MasonryGrid where Item == Work {
    
    /// Convenience initializer for Work items with automatic height calculation
    init(
        works: [Work],
        columnWidth: CGFloat,
        spacing: CGFloat = 4,
        @ViewBuilder content: @escaping (Work) -> Content
    ) {
        self.init(
            items: works,
            columns: 2,
            spacing: spacing,
            content: content,
            heightProvider: { work in
                // Calculate cell height based on cover aspect ratio
                // Cover aspect ratio: 3:4 (0.75) to 4:3 (1.33)
                // Default to 1:1 if no cover
                let aspectRatio = work.coverAspectRatio ?? 1.0
                let imageHeight = columnWidth / aspectRatio
                let infoHeight: CGFloat = 60 // Title + creator info
                return imageHeight + infoHeight
            }
        )
    }
}

// MARK: - Work extension for aspect ratio

extension Work {
    /// Cover image aspect ratio (width / height)
    /// Returns nil if no cover, defaults handled by caller
    var coverAspectRatio: CGFloat? {
        // For now, return a default ratio
        // In production, this would be stored with the thumbnail URL
        // or extracted from image metadata
        guard thumbnailUrl != nil else { return nil }
        
        // Default to 3:4 portrait (0.75) as most common for mobile screenshots
        return 0.75
    }
}

