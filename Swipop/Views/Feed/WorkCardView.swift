//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    @Binding var triggerLikeAnimation: Bool
    
    var body: some View {
        WorkWebView(work: work)
            .ignoresSafeArea()
    }
}

#Preview {
    WorkCardView(work: .sample, triggerLikeAnimation: .constant(false))
        .preferredColorScheme(.dark)
}
