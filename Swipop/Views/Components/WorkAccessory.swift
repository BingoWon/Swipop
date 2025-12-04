//
//  WorkAccessory.swift
//  Swipop
//
//  Floating work accessory with Liquid Glass (iOS 26) / Material (iOS 18)
//

import SwiftUI

// MARK: - Work Accessory Content (Shared)

struct WorkAccessoryContent: View {
    @Binding var showDetail: Bool
    
    private let feed = FeedViewModel.shared
    private var currentWork: Work? { feed.currentWork }
    private var creator: Profile? { currentWork?.creator }
    
    var body: some View {
        HStack(spacing: 0) {
            Button { showDetail = true } label: {
                workInfoLabel
            }
            
            Spacer(minLength: 0)
            
            Divider().frame(height: 18).overlay(Color.border)
            
            navigationButtons
            
            Spacer().frame(width: 4)
        }
        .foregroundStyle(.primary)
    }
    
    private var workInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 28, height: 28)
                .overlay {
                    Text(creator?.initial ?? "?")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentWork?.title.isEmpty == false ? currentWork!.title : "Untitled")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("@\(creator?.handle ?? "unknown")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 12)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToPrevious()
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 36)
            }
            .opacity(feed.currentIndex == 0 ? 0.3 : 1)
            
            Divider().frame(height: 18).overlay(Color.border)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    feed.goToNext()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 36)
            }
        }
    }
}

// MARK: - Floating Work Accessory

struct FloatingWorkAccessory: View {
    @Binding var showDetail: Bool
    
    var body: some View {
        WorkAccessoryContent(showDetail: $showDetail)
            .frame(height: 48)
            .modifier(GlassBackgroundModifier())
            .padding(.horizontal, 20)
    }
}

// MARK: - Glass Background Modifier

private struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Liquid Glass
            content
                .background(Capsule().fill(.clear).glassEffect())
        } else {
            // iOS 18: Ultra thin material
            content
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        }
    }
}

#Preview("Floating") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingWorkAccessory(showDetail: .constant(false))
        }
    }
}

