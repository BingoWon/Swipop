//
//  FeedView.swift
//  Swipop
//
//  Full-screen vertical feed of works
//

import SwiftUI

struct FeedView: View {
    
    @Binding var showLogin: Bool
    @State private var feedViewModel = FeedViewModel.shared
    
    var body: some View {
        ZStack {
            Color.black
            
            // Current work - full screen
            if let work = feedViewModel.currentWork {
                WorkCardView(
                    work: work,
                    showLogin: $showLogin,
                    onPrevious: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            feedViewModel.goToPrevious()
                        }
                    },
                    onNext: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            feedViewModel.goToNext()
                        }
                    }
                )
                .id(feedViewModel.currentIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .top)
                ))
            }
        }
        .ignoresSafeArea(.all)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let verticalMovement = value.translation.height
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if verticalMovement < -50 {
                            feedViewModel.goToNext()
                        } else if verticalMovement > 50 {
                            feedViewModel.goToPrevious()
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
