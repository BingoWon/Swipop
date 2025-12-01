//
//  FeedViewModel.swift
//  Swipop
//

import Foundation

@Observable
final class FeedViewModel {
    
    static let shared = FeedViewModel()
    
    private(set) var works: [Work] = Work.samples
    private(set) var currentIndex = 0
    
    var currentWork: Work? {
        guard currentIndex >= 0 && currentIndex < works.count else { return nil }
        return works[currentIndex]
    }
    
    private init() {}
    
    func goToNext() {
        guard currentIndex < works.count - 1 else { return }
        currentIndex += 1
    }
    
    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
}
