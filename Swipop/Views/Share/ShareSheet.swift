//
//  ShareSheet.swift
//  Swipop
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    
    let work: Work
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "\(work.title) on Swipop"
        let url = URL(string: "https://swipop.app/work/\(work.id)")!
        
        return UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

