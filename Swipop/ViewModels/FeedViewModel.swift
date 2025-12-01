//
//  FeedViewModel.swift
//  Swipop
//
//  Shared state for feed navigation
//

import Foundation

@Observable
final class FeedViewModel {
    
    static let shared = FeedViewModel()
    
    var currentWork: Work?
    var works: [Work] = Work.samples
    var currentIndex: Int = 0 {
        didSet {
            if currentIndex >= 0 && currentIndex < works.count {
                currentWork = works[currentIndex]
            }
        }
    }
    
    private init() {
        if !works.isEmpty {
            currentWork = works[0]
        }
    }
    
    func goToNext() {
        if currentIndex < works.count - 1 {
            currentIndex += 1
        }
    }
    
    func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

