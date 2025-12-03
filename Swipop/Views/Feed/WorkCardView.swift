//
//  WorkCardView.swift
//  Swipop
//

import SwiftUI

struct WorkCardView: View {
    
    let work: Work
    
    var body: some View {
        WorkWebView(work: work)
            .ignoresSafeArea()
    }
}

#Preview {
    WorkCardView(work: .sample)
        .preferredColorScheme(.dark)
}
