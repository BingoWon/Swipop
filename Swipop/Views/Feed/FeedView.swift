//
//  FeedView.swift
//  Swipop
//
//  Vertical scrolling feed of works
//

import SwiftUI

struct FeedView: View {
    
    @State private var works: [Work] = Work.samples
    @State private var currentIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Current work
                if !works.isEmpty {
                    WorkCardView(work: works[currentIndex])
                        .id(currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .move(edge: .top)
                        ))
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let verticalMovement = value.translation.height
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if verticalMovement < -50 {
                                // Swipe up - next
                                goToNext()
                            } else if verticalMovement > 50 {
                                // Swipe down - previous
                                goToPrevious()
                            }
                        }
                    }
            )
        }
    }
    
    private func goToNext() {
        if currentIndex < works.count - 1 {
            currentIndex += 1
        }
    }
    
    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

#Preview {
    FeedView()
        .preferredColorScheme(.dark)
}

