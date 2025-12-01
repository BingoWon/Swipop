//
//  FeedView.swift
//  Swipop
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    private let feed = FeedViewModel.shared
    
    init(showLogin: Binding<Bool>) {
        self._showLogin = showLogin
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            if let work = feed.currentWork {
                WorkCardView(work: work, showLogin: $showLogin)
                    .id(feed.currentIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .top)
                    ))
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if value.translation.height < -50 {
                            feed.goToNext()
                        } else if value.translation.height > 50 {
                            feed.goToPrevious()
                        }
                    }
                }
        )
    }
}

#Preview {
    FeedView(showLogin: .constant(false))
        .preferredColorScheme(.dark)
}
