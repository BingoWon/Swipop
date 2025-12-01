//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @Binding var triggerLikeAnimation: Bool
    
    var body: some View {
        ZStack {
            WorkWebView(work: work)
            
            // Creator info overlay (bottom-left)
            VStack {
                Spacer()
                creatorOverlay
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .padding(.bottom, 160)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Creator Overlay
    
    private var creatorOverlay: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(work.creator?.displayName?.prefix(1).uppercased() ?? "C")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(work.creator?.displayName ?? "Creator")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                
                Text(work.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
    }
}

#Preview {
    WorkCardView(work: .sample, triggerLikeAnimation: .constant(false))
        .preferredColorScheme(.dark)
}
