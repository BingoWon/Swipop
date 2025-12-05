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
            let shortestColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columnItems[shortestColumn].append(item)
            columnHeights[shortestColumn] += heightProvider(item) + spacing
        }
        
        return columnItems[column]
    }
}

// MARK: - Work-specific convenience initializers

extension MasonryGrid where Item == Work {
    
    /// Default aspect ratio when thumbnail_aspect_ratio is not set
    private static var defaultAspectRatio: CGFloat { 0.75 }  // 3:4 portrait
    
    /// Discover page: 2 columns with title and creator info
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
                let ratio = max(work.thumbnailAspectRatio ?? Self.defaultAspectRatio, 0.1)
                let safeColumnWidth = max(columnWidth, 1)
                let imageHeight = safeColumnWidth / ratio
                let infoHeight: CGFloat = 60 // Title + creator info
                return imageHeight + infoHeight
            }
        )
    }
    
    /// Profile page: custom columns, thumbnail only (no info)
    init(
        works: [Work],
        columnWidth: CGFloat,
        columns: Int,
        spacing: CGFloat = 2,
        @ViewBuilder content: @escaping (Work) -> Content
    ) {
        self.init(
            items: works,
            columns: columns,
            spacing: spacing,
            content: content,
            heightProvider: { work in
                let ratio = max(work.thumbnailAspectRatio ?? Self.defaultAspectRatio, 0.1)
                let safeColumnWidth = max(columnWidth, 1)
                return safeColumnWidth / ratio
            }
        )
    }
}
