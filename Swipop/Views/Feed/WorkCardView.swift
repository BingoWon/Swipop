//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    let showLikeAnimation: Bool
    
    var body: some View {
        ZStack {
            WorkWebView(work: work)
            
            if showLikeAnimation {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WorkCardView(work: .sample, showLikeAnimation: false)
        .preferredColorScheme(.dark)
}
